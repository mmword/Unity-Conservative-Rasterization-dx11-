using UnityEngine;
using System.Collections;

public class DynamicEntity : MonoBehaviour
{
    public RenderToUAVTex uavRender;
    public bool isStatic = false;
    public RenderToUAVTex.DrawMethod drawMethod = RenderToUAVTex.DrawMethod.FAST_VS;

    RenderToUAVTex.EnityDesc desc;

    // Use this for initialization
    void Start()
    {
        MeshFilter filter = GetComponent<MeshFilter>();
        desc = new RenderToUAVTex.EnityDesc();
        desc.mesh = filter.sharedMesh;
        desc.transform = transform;
        desc.drawMethod = drawMethod;
        desc.isStatic = isStatic;
        uavRender.AddEntity(desc);
    }
}
