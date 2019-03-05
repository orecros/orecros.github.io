/*
 * Andrew Tollett, 2018
 * This is some example code I ripped out of an old project of mine.
 * I, obviously I guess, did not write the poisson disc sampling algorithm.
 * I did put it into C# though, and the rest of the code was created by me.
 */

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(BlockRegion))]
public class BlockRegionInspector : Editor
{
    private BlockRegion region;
    private Transform handleTransform;
    private Quaternion handleRotation;

    private void OnSceneGUI()
    {
        region = target as BlockRegion;
        handleTransform = region.transform;
        handleRotation = Tools.pivotRotation == PivotRotation.Local ?
             handleTransform.rotation : Quaternion.identity;

        //draw rectangle wireframe
        float w = region.width / 2;
        float h = region.height / 2;

        Vector3 p0 = GetWorldPoint(new Vector3(w, 0, h));
        Vector3 p1 = GetWorldPoint(new Vector3(w, 0, -h));
        Vector3 p2 = GetWorldPoint(new Vector3(-w, 0, -h));
        Vector3 p3 = GetWorldPoint(new Vector3(-w, 0, h));

        Handles.DrawLine(p0, p1);
        Handles.DrawLine(p1, p2);
        Handles.DrawLine(p2, p3);
        Handles.DrawLine(p3, p0);
        Handles.DrawLine(p0, p2);
        Handles.DrawLine(p1, p3);
    }

    private Vector3 GetWorldPoint(Vector3 point)
    {
        return handleTransform.TransformPoint(point);
    }
}
