/*
 * Andrew Tollett, 2018
 * This is some example code I ripped out of an old project of mine.
 * the code for Bezier Splines and Bezier Curves (called from here but not included here) was created
 * by closely following this tutorial: https://catlikecoding.com/unity/tutorials/curves-and-splines/
 * All other code in this project, including all the code in this file, was written by me.
 */

﻿using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(SlopeGenerator))]
public class SlopeGeneratorInspector : Editor
{
    private SlopeGenerator slope;

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        slope = target as SlopeGenerator;

        if (GUILayout.Button("Generate Slope"))
        {
            DestroySlope();

            //create object name
            string meshPath = "Assets/Models/Generated/" + slope.name + ".asset";
            //start undo event
            Undo.SetCurrentGroupName("Generate Slope");

            //generate mesh
            Mesh mesh = slope.MakeMesh();

            //save mesh
            AssetDatabase.CreateAsset(mesh, meshPath);
            AssetDatabase.SaveAssets();
            //AssetDatabase.LoadAssetAtPath(meshPath,);
            Undo.RegisterCreatedObjectUndo(mesh, "Generate Mesh");

            //create mesh object
            GameObject go = slope.CreateSlopeObject(mesh);
            Undo.RegisterCreatedObjectUndo(go, "Generate Slope");

            //end undo event
            Undo.CollapseUndoOperations(Undo.GetCurrentGroup());

            EditorUtility.SetDirty(slope);
        }
        if (GUILayout.Button("Destroy Slope"))
        {
            DestroySlope();
        }
    }
    void DestroySlope()
    {
        if (slope.slopeObject != null)
        {
            Undo.DestroyObjectImmediate(slope.slopeObject);
            EditorUtility.SetDirty(slope);

            if (slope.transform.childCount > 0)
            {
                slope.slopeObject = slope.transform.GetChild(slope.transform.childCount - 1).gameObject;
            }
        }
    }
}
