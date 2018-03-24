using UnityEngine;
using System.Collections;

public class PresentUAVContentAsGS : MonoBehaviour {

    public MonoBehaviour content;
    public Env env;
    public Shader drawShader;

    Camera cam;
    Material debugMaterial;

    private void Start()
    {
        cam = GetComponent<Camera>();
        debugMaterial = new Material(drawShader);
    }

    private void OnPostRender()
    {
        Presentable uavContent = (Presentable)content;
        if (debugMaterial != null && uavContent != null)
        {
            Matrix4x4 toMVP = cam.projectionMatrix * cam.worldToCameraMatrix * env.transform.localToWorldMatrix;
            debugMaterial.SetMatrix("toMVP", toMVP);
            debugMaterial.SetTexture("gVoxelList", uavContent.uavContent);
            debugMaterial.SetVector("voxelDim", new Vector3(env.xCells, env.yCells, env.zCells));
            debugMaterial.SetPass(0);
            Graphics.DrawProcedural(MeshTopology.Points, env.xCells* env.yCells* env.zCells);
        }
    }

    private void OnDestroy()
    {
        if (debugMaterial != null)
            DestroyImmediate(debugMaterial);
    }
}
