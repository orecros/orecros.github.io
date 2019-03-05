using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(BezierSpline))]
public class BlockPlacer : MonoBehaviour
{
    public bool rotateToCurve; //if left unchecked, all blocks will face (0,0,0), otherwise they will be angled along the curve
    [Range(0,0.5f)]public float endPadding; //how far from each end of the spline should the first and last block be placed?
    public int polyLineResolution = 50; //how many segments should the spline's approximation be built out of? more is more accurate but slower.

    public GameObject blockPrefab; //the prefab spawned
    public BezierSpline spline;
    public int blockCount = 5; //the amount of blocks used for the next generation
    public GameObject blocksPile; //a reference to the most recently created bundle of blocks
    public GameObject GenerateBlocks()
    {
        blocksPile = new GameObject();
        blocksPile.transform.SetParent(transform);

        //number this pile appropriately if there are already some piles on it
        int m = 0;
        for (int n = 0; n < transform.childCount; n++)
        {
            if(transform.GetChild(n).name.Contains("pile"))
            {
                m++;
            }
        }
        blocksPile.name = "pile " + (m + 1);

        //convert the spline into a polyLine
        PolyLine polyLine = spline.GetPolyLine(polyLineResolution);

        //spawn the blocks
        for (int i = 0; i < blockCount; i++)
        {
            //get the fraction along the polyline to start at
            float t = (float)i / (blockCount - 1);
            if(endPadding != 0)
            {
                t = Pad(t);
            }

            //get the position that is along the polyline
            Vector3 point = polyLine.GetPoint(t);
            Quaternion orientation;
            if (rotateToCurve)
            {
                Vector3 dir = polyLine.GetDirection(t).Flatten();
                orientation = Quaternion.LookRotation(dir, Vector3.up);
            }
            else
            {
                orientation = Quaternion.identity;
            }

            GameObject go = Instantiate(blockPrefab, point, orientation, blocksPile.transform);
            go.name = "block " + i;
            }

        return blocksPile;
    }

    //reposition t to account for the padding amount
    float Pad(float t)
    {
        return endPadding + t * (1 - endPadding * 2);
    }


    private void OnValidate()
    {
        spline = GetComponent<BezierSpline>();
       if(blockCount < 1)
       {
            blockCount = 1;
       }
    }
}
