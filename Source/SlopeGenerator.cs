/*
 * Andrew Tollett, 2018
 * This is some example code I ripped out of an old project of mine.
 * the code for Bezier Splines and Bezier Curves (called from here but not included here) was created 
 * by closely following this tutorial: https://catlikecoding.com/unity/tutorials/curves-and-splines/
 * All other code in this project, including all the code in this file, was written by me.
 */

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum SlopeType
{
    Both, //both sides of the surface will be sloped
    Left, //the left side of the surface will be sloped, the right will be sheer
    Right //vice versa
}

[RequireComponent(typeof(BezierSpline))]
public class SlopeGenerator : MonoBehaviour
{
    //public int polyLineResolution = 50; //the amount of segments the polyline should be built out of. should keep this a larger number than segments
    public int segments = 20; //the amount segments to construct the slope out of. triangle count is 6*segments + 2
    public float height = 5; //the height of the center pole of the slope
    [Range(45,90)]public float slope = 70; //the angle of the sloped surface against the pole. Width is derived from this value and the height
    public SlopeType slopeType; //which sides of the slope object will be sloped and which will be sheer
    public Material meshMaterial;

    private Mesh mesh;
    private Vector3[] vertices;
    private Vector2[] uv;
    private int[] triangles;


    public GameObject slopeObject; //GenerateSlope creates a gameObject and stores it here

    private void Start()
    {
    }
    private void OnValidate()
    {
        if(segments < 1)
        {
            segments = 1;
        }
    }

    //shorthand for creating a triangle from the vertex table
    private void SetTri(int firstIndex, int v1, int v2, int v3)
    {
        triangles[firstIndex] = v1;
        triangles[firstIndex + 1] = v2;
        triangles[firstIndex + 2] = v3;
    }

    //create the gameobject to attach the mesh to
    public GameObject CreateSlopeObject(Mesh mesh)
    {
        slopeObject = new GameObject();
        slopeObject.transform.position = Vector3.zero;
        slopeObject.transform.SetParent(transform,false);
        
        //number this slope appropriately if there are already some slopes as children of this gameobject
        int m = 0;
        for (int n = 0; n < transform.childCount; n++)
        {
            if (transform.GetChild(n).name.Contains("slope"))
            {
                m++;
            }
        }
        slopeObject.name = "slope " + (m + 1);


        slopeObject.AddComponent<MeshFilter>().mesh = mesh;
        slopeObject.AddComponent<MeshRenderer>().material = meshMaterial;
        slopeObject.AddComponent<MeshCollider>().sharedMesh = mesh;

        return slopeObject;
    }

    //builds the slope's mesh from the attached BezierSpline
    public Mesh MakeMesh()
    {
        BezierSpline spline = GetComponent<BezierSpline>();

        /*
         *  This method ended up giving a worse result, as spacing points parametrically-evenly
         *  along a spline squeezes more points in along sharp turns, while a polyline would
         *  supply less points leading to a rougher edge
         *  
         *  //convert the supplied spline to a polyline
         *  PolyLine line = spline.GetLocalPolyLine(polyLineResolution);
         */

        Mesh mesh = new Mesh
        {
            name = "generated slope"
        };

        float width = Mathf.Tan((90 - slope) * Mathf.Deg2Rad) * height;

        //create the template shape for the slopes from the supplied width, height, and slopeType
        Vector3 v0, v1, v2;
        if(slopeType == SlopeType.Both)
        {
            v0 = new Vector3(-width, 0, 0);
            v1 = new Vector3(0, height, 0);
            v2 = new Vector3(width, 0, 0);
        }
        else if(slopeType == SlopeType.Left)
        {
            v0 = Vector3.zero;
            v1 = new Vector3(0, height, 0);
            v2 = new Vector3(width, 0, 0);
        }
        else //if(slopeType == SlopeType.Right)
        {

            v0 = new Vector3(-width, 0, 0);
            v1 = new Vector3(0, height, 0);
            v2 = Vector3.zero;
        }

        //build the arrays to store the parts of the mesh
        vertices = new Vector3[(segments + 1) * 4 + 6];
        uv = new Vector2[(segments + 1) * 4 + 6];
        triangles = new int[(6 * segments + 2) * 3];

        //make the vertices, make the triangles along the slope
        for (int s = 0; s < segments + 1; s++)
        {
            float t = (float)s / segments; //parametric ditance along the polyline
            Vector3 v = spline.GetLocalPoint(t);
            Quaternion q = Quaternion.LookRotation(spline.GetDirection(t), Vector3.up);
            /*
             *  //use this section to use a poly line instead
             *  Vector3 v = line.GetPoint(t);
             *  Quaternion q = Quaternion.LookRotation(line.GetDirection(t), Vector3.up);
             */

            //set the 4* vertices of the triangle
            //duplicating v1 creates a UV seam along the top for a nicer application of the texture
            vertices[4 * s + 0] = v + q * v1;
            vertices[4 * s + 1] = v + q * v2;
            vertices[4 * s + 2] = v + q * v0;
            vertices[4 * s + 3] = v + q * v1; 

            //set uvs
            uv[4 * s + 0] = new Vector2(1 - t, 0.0f);
            uv[4 * s + 1] = new Vector2(1 - t, .25f);
            uv[4 * s + 2] = new Vector2(1 - t, .50f);
            uv[4 * s + 3] = new Vector2(1 - t, .75f);

            //draw triangles between this and the last segment (if it exists)
            if (s != 0)
            {
                int s4 = 4 * s;
                int startTriIndex = 18 * (s - 1);
                SetTri(startTriIndex + 0, s4, s4 + 1, s4 - 4);
                SetTri(startTriIndex + 3, s4 + 1, s4 - 3, s4 - 4);
                SetTri(startTriIndex + 6, s4 + 1, s4 + 2, s4 - 3);
                SetTri(startTriIndex + 9, s4 + 2, s4 - 2, s4 - 3);
                SetTri(startTriIndex + 12, s4 + 2, s4 + 3, s4 - 2);
                SetTri(startTriIndex + 15, s4 + 3, s4 - 1, s4 - 2);
            }
        }
        
        //make the end caps. again, using new vertices to make UV seams
        int end = (segments + 1) * 4;

        //build cap 1
        vertices[end] = vertices[0]; //cap 1 v0
        vertices[end + 1] = vertices[1]; //cap 1 v1
        vertices[end + 2] = vertices[2]; //cap 1 v24

        //build cap 2. vertices "out of order" to flip the normal
        vertices[end + 3] = vertices[4 * segments]; //cap 2 v0
        vertices[end + 4] = vertices[4 * segments + 2]; //cap 2 v2
        vertices[end + 5] = vertices[4 * segments + 1]; //cap 2 v1

        //mark uv's for cap 1
        uv[end] = new Vector2(0.125f, 1); 
        uv[end + 1] = new Vector2(0.25f, .75f);
        uv[end + 2] = new Vector2(0, .75f);

        //mark uv's for cap 2
        //note the normal ordering despite flipping previously.
        uv[end + 3] = new Vector2(0.125f, 1); 
        uv[end + 4] = new Vector2(0.25f, .75f); 
        uv[end + 5] = new Vector2(0, .75f);


        SetTri(18 * segments, end, end + 1, end + 2);
        SetTri(18 * segments + 3, end + 3, end + 4, end + 5);

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uv;

        return mesh;
    }
}
