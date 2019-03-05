using UnityEditor;
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
