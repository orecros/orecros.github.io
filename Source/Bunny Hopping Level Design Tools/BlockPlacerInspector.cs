/*
 * Andrew Tollett, 2018
 * This is some example code I ripped out of an old project of mine.
 * the code for Bezier Splines and Bezier Curves (called from here but not included here) was created
 * by closely following this tutorial: https://catlikecoding.com/unity/tutorials/curves-and-splines/
 * All other code in this project, including all the code in this file, was written by me.
 */

﻿using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(BlockPlacer))]
public class BlockPlacerInspector : Editor
{
    private BlockPlacer placer;

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        placer = target as BlockPlacer;

        if (GUILayout.Button("Generate Blocks"))
        {
            if(placer.blocksPile != null && placer.blocksPile.transform.parent == placer.transform)
            {
                DestroyBlocks();
            }

            GameObject go = placer.GenerateBlocks();
            Undo.RegisterCreatedObjectUndo(go, "Generate Blocks");
            EditorUtility.SetDirty(placer);
        }
        if (GUILayout.Button("Destroy Blocks"))
        {
            DestroyBlocks();
        }

    }

    void DestroyBlocks()
    {
        if (placer.blocksPile != null)
        {
            Undo.DestroyObjectImmediate(placer.blocksPile);
            EditorUtility.SetDirty(placer);

            if (placer.transform.childCount > 0)
            {
                placer.blocksPile = placer.transform.GetChild(placer.transform.childCount - 1).gameObject;
            }
        }
    }
}
