/*
 * Andrew Tollett, 2018
 * This is some example code I ripped out of an old project of mine.
 * I, obviously I guess, did not write the poisson disc sampling algorithm.
 * I did put it into C# though, and the rest of the code was created by me.
 */

﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlockRegion : MonoBehaviour
{
    bool spawned = false;
    List<Vector2> seeds;
    Vector3[] spawns;

    public GameObject blockPrefab;
    public float rMin = 1;
    public float rMax = 2;
    public float width;
    public float height;
    float k = 30;

    private void Awake()
    {
        seeds = new List<Vector2>();
    }

    //populate this region with blocks
    public void Spawn()
    {
        Vector2[] spawns2D = Generate2DPoints();

        spawns = new Vector3[spawns2D.Length];

        for(int n = 0; n < spawns2D.Length; n++)
        {
            spawns[n] = ConvertRawPoint(spawns2D[n]);

            GameObject go = Instantiate(blockPrefab, spawns[n], Quaternion.identity, transform);
            go.name = "generated block " + n;
        }

        spawned = true;
    }
    //add a seed that is already in local grid-space
    public void AddSeed(Vector2 seed2D)
    {
        seeds.Add(seed2D);
    }
    //convert this seed to local grid-space then add it
    public void AddSeed(Vector3 seed3D)
    {
        Debug.DrawRay(seed3D, Vector3.up * 2, Color.red, 10);

        //convert to local space
        Vector3 tempseed = transform.InverseTransformPoint(seed3D);

        //discard Y component
        Vector2 seed2D = (new Vector2(tempseed.x, tempseed.z));

        //offset from -.5/.5 to 0/1 range
        seed2D += new Vector2(width / 2, height / 2);

        //add that 2D seed
        AddSeed(seed2D);
    }
    //gets a list of all the blocks this region has spawned
    public Vector3[] GetSpawns()
    {
        if (spawned)
            return spawns;
        else
            return new Vector3[0];
    }

    //generate the set of points to spawn the blocks at
    Vector2[] Generate2DPoints()
    {
        //step 0 - initialize
        float w = rMin / Mathf.Sqrt(2f);
        int cols = (int)Mathf.Ceil(width / w);
        int rows = (int)Mathf.Ceil(height / w);

        List<Vector2> points = new List<Vector2>();
        List<int> activePoints = new List<int>();
        int[,] grid = new int[rows, cols];
        for (int r = 0; r < rows; r++)
        {
            for (int c = 0; c < cols; c++)
            {
                grid[r, c] = -1;
            }
        }

        //step 1

        //check every seed and remove the ones that are too far to count
        for(int n = seeds.Count - 1; n >= 0; n--)
        {
            Vector2 seed = seeds[n];

            if(seed.x < -rMin || seed.x > width + rMin
                || seed.y < -rMin || seed.y > height + rMin)
            {
                seeds.RemoveAt(n);
            }
        }

        List<Vector2> tempseeds = new List<Vector2>();

        foreach(Vector2 seed in seeds)
        {
            tempseeds.Add(seed);
        }

        //try and spawn some things from seed points
        while (tempseeds.Count != 0)
        {
            //select a random seed
            int index = (int)(Random.value * tempseeds.Count);

            //try a bunch of times to create a point in range of this one
            bool found = false;
            for (int tries = 0; tries < k; tries++)
            {
                //create a point
                float angle = Random.Range(0, 2 * Mathf.PI);
                float dist = Random.Range(rMin, rMax);

                Vector2 pos = tempseeds[index] + new Vector2(
                    Mathf.Cos(angle) * dist,
                    Mathf.Sin(angle) * dist
                    );

                //if this point is out of bounds, throw it out
                if (pos.x < 0 || pos.x > width || pos.y < 0 || pos.y > height)
                {
                    continue;
                }

                //get the grid position of that point
                int i = (int)(pos.y / w);
                int j = (int)(pos.x / w);

                //check adjacent grid points
                bool ok = true;
                for (int row = i - 1; row <= i + 1; row++)
                {
                    //skip out of bounds row checks
                    if (row < 0 || row >= rows)
                        continue;
                    for (int col = j - 1; col <= j + 1; col++)
                    {
                        //skip out of bounds col checks
                        if (col < 0 || col >= cols)
                            continue;

                        int neighbor = grid[row, col];
                        if (neighbor != -1)
                        {
                            //if this neighbor exists, see if are too close
                            float d = Vector2.Distance(points[neighbor], pos);
                            if (d < rMin)
                            {
                                //too close, this point fails
                                ok = false;
                                break;
                            }
                        }
                    }
                }

                //then check every seed (can't use the grid because seeds are out of grid bounds)
                //tempseeds is the "active list" so just the full list in seeds
                if (ok)
                {
                    foreach (Vector2 seed in seeds)
                    {
                        float d = Vector2.Distance(seed, pos);
                        if (d < rMin)
                        {
                            //too close, this point fails
                            ok = false;
                            break;
                        }
                    }
                }

                //see if that worked
                if (ok)
                {
                    found = true;
                    int n = points.Count;
                    points.Add(pos);
                    grid[i, j] = n;
                    activePoints.Add(n);

                    DebugDrawConnection(tempseeds[index], pos, Color.red);

                    break;
                }
                //if it didnt work continue
            }

            if (!found)
            {
                //this point spawned nothing after a billion tries
                //remove it from tempseeds
                tempseeds.RemoveAt(index);
            }
        }

        //no more seeds should be left, but we might have some new points

        //if after all that, no points were created, pick a random point in space to start with
        if (points.Count == 0)
        {
            float x = Random.Range(0, width); //create a random point
            float y = Random.Range(0, height);
            int i = (int)(y / w); //convert to grid position
            int j = (int)(x / w);
            points.Add(new Vector2(x, y));
            grid[i, j] = 0;
            activePoints.Add(0);
        }

        //step 2
        while (activePoints.Count != 0)
        {
            //select a random active point
            int index = activePoints[(int)(Random.value * activePoints.Count)];

            //try a bunch of times to create a point in range of this one
            bool found = false;
            for (int tries = 0; tries < k; tries++)
            {
                //create a point
                float angle = Random.Range(0, 2 * Mathf.PI);
                float dist = Random.Range(rMin, rMax);

                Vector2 pos = points[index] + new Vector2(
                    Mathf.Cos(angle) * dist,
                    Mathf.Sin(angle) * dist
                    );

                //if this point is out of bounds, throw it out
                if (pos.x < 0 || pos.x > width || pos.y < 0 || pos.y > height)
                {
                    continue;
                }

                //get the grid position of that point
                int i = (int)(pos.y / w);
                int j = (int)(pos.x / w);

                //check adjacent grid points
                bool ok = true;
                for (int row = i - 1; row <= i + 1; row++)
                {
                    //skip out of bounds row checks
                    if (row < 0 || row >= rows)
                        continue;
                    for (int col = j - 1; col <= j + 1; col++)
                    {
                        //skip out of bounds col checks
                        if (col < 0 || col >= cols)
                            continue;

                        int neighbor = grid[row, col];
                        if (neighbor != -1)
                        {
                            //if this neighbor exists, see if are too close
                            float d = Vector2.Distance(points[neighbor], pos);
                            if (d < rMin)
                            {
                                //too close, this point fails
                                ok = false;
                                break;
                            }
                        }
                    }
                }

                //if you still haven't failed, check all seeds as well
                if(ok)
                {
                    for(int n = 0; n < seeds.Count; n++)
                    {
                        float d = Vector2.Distance(seeds[n], pos);
                        if(d < rMin)
                        {
                            //too close, this point fails
                            ok = false;
                            break;
                        }
                    }
                }

                //see if that worked
                if (ok)
                {
                    found = true;
                    int n = points.Count;
                    points.Add(pos);
                    grid[i, j] = n;
                    activePoints.Add(n);

                    DebugDrawConnection(points[index], pos, Color.green);

                    break;
                }
                //if it didnt work continue
            }

            if (!found)
            {
                //this point spawned nothing after a billion tries
                //remove it from active points
                activePoints.Remove(index);
            }
        }

        return points.ToArray();
    }

    //this bit draws some fat arrows between adjacent points
    void DebugDrawConnection(Vector2 seed1, Vector2 seed2, Color color)
    {
        float time = 100;

        Vector3 p1 = ConvertRawPoint(seed1);
        Vector3 p2 = ConvertRawPoint(seed2);

        Vector3 crossLine = Vector3.Cross(p2 - p1, Vector3.up).normalized;

        Debug.DrawRay(p1, Vector3.up, color, time);
        Debug.DrawRay(p2, Vector3.up, color, time);
        Debug.DrawLine(p1 + Vector3.up - crossLine / 2, p2 + Vector3.up, color, time);
        Debug.DrawLine(p1, p2 + Vector3.up, color, time);
        Debug.DrawLine(p1 + Vector3.up + crossLine / 2, p2 + Vector3.up, color, time);
        Debug.DrawRay(p1 + Vector3.up + crossLine / 2, -crossLine, color, time);
    }
    Vector3 ConvertRawPoint(Vector2 rawPoint)
    {
        rawPoint -= new Vector2(width / 2, height / 2);
        return transform.TransformPoint(new Vector3(rawPoint.x, 0, rawPoint.y));
    }

}
