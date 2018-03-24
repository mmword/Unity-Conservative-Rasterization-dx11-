using UnityEngine;
using UnityEngine.Rendering;
using System;
using System.Collections.Generic;

[RequireComponent(typeof(Camera))]
public class RenderToUAVTex : MonoBehaviour,Presentable {

    public enum DrawMethod
    {
        FAST_VS,
        STABLE_GS
    }

    [Serializable]
    public class EnityDesc
    {
        public Mesh mesh;
        public Transform transform;
        public bool isStatic;
        public DrawMethod drawMethod;
        public bool IsStaticNeedToDraw;
    }

    public Env env;
    public Shader ConservativeRaster;
    public bool oneShot;

    public event Action OnReadyToUse;

    public bool initialized { get; private set; }
    public RenderTexture uavTex3D { get; private set; }

    public RenderTexture uavContent
    {
        get
        {
            return uavTex3D;
        }
    }

    List<EnityDesc> StableRenderEntities = new List<EnityDesc>();
    List<EnityDesc> FastRenderEntities = new List<EnityDesc>();
    int numFrames;

    Action DrawTechnique;
    Material mRaster;
    Camera cam;

    bool CreateResources()
    {
        if(mRaster == null)
        {
            if (ConservativeRaster == null)
                return false;
            mRaster = new Material(ConservativeRaster);
        }
        if(uavTex3D == null)
        {
            uavTex3D = new RenderTexture(env.xCells, env.yCells, 0, RenderTextureFormat.RFloat);
            uavTex3D.volumeDepth = env.zCells;
            uavTex3D.dimension = TextureDimension.Tex3D;
            uavTex3D.enableRandomWrite = true;
            uavTex3D.filterMode = FilterMode.Point;
            uavTex3D.generateMips = false;
            uavTex3D.useMipMap = false;
            if (!uavTex3D.Create())
                return false;
        }
        return true;
    }

    void SetView(Vector3 axis, float farAway = 10F)
    {
        // transform.position = (EnvCube.transform.position + EnvCube.transform.localScale * 0.5F) - Vector3.forward * (EnvCube.transform.localScale.z + 10F);
        Vector3 relativePos = env.transform.position + env.transform.localScale * 0.5F;
        transform.position = relativePos - axis * (Vector3.Dot(axis, env.transform.localScale) + farAway);
        transform.rotation = Quaternion.LookRotation(relativePos - transform.position);
    }

    void ClearTechnique()
    {
        Graphics.SetRandomWriteTarget(1, uavTex3D);
        mRaster.SetPass(2);
        Graphics.DrawProcedural(MeshTopology.Points, env.xCells * env.yCells * env.zCells);
    }

    void ConservativeGSTechnique()
    {
        Graphics.SetRandomWriteTarget(1, uavTex3D);
        mRaster.SetPass(0);
        if (StableRenderEntities != null && StableRenderEntities.Count > 0)
        {
            foreach (EnityDesc ent in StableRenderEntities)
            {
                if (!ent.isStatic || ent.IsStaticNeedToDraw)
                {
                    Graphics.DrawMeshNow(ent.mesh, ent.transform.localToWorldMatrix);
                    ent.IsStaticNeedToDraw = false;
                }
            }
        }
    }

    void ConservativeVSTechnique()
    {
        Graphics.SetRandomWriteTarget(1, uavTex3D);
        mRaster.SetPass(1);
        if (FastRenderEntities != null && FastRenderEntities.Count > 0)
        {
            foreach (EnityDesc ent in FastRenderEntities)
            {
                if (!ent.isStatic || ent.IsStaticNeedToDraw)
                {
                    Graphics.DrawMeshNow(ent.mesh, ent.transform.localToWorldMatrix);
                    ent.IsStaticNeedToDraw = false;
                }
            }
        }
    }

    public void AddEntity(EnityDesc desc)
    {
        if(desc != null)
        {
            if (desc.drawMethod == DrawMethod.FAST_VS)
                FastRenderEntities.Add(desc);
            else
                StableRenderEntities.Add(desc);
        }
    }

    public void RemoveEntity(EnityDesc desc)
    {
        if (desc.drawMethod == DrawMethod.FAST_VS)
            FastRenderEntities.Remove(desc);
        else
            StableRenderEntities.Remove(desc);
    }

    // Use this for initialization
    void Start () {
        initialized = false;
        if (!CreateResources())
            return;
        cam = GetComponent<Camera>();
        SetView(Vector3.forward);
        cam.orthographic = true;
        cam.enabled = false;
        Vector3 scale = env.transform.localScale * 0.5F;
        cam.projectionMatrix = Matrix4x4.Ortho(-scale.x, scale.x, -scale.y, scale.y, 0.1F, 1000F);
        cam.cullingMask = 0;

        Vector3 vox_dim = new Vector3(env.xCells, env.yCells, env.zCells);

        mRaster.SetMatrix("toCube", env.transform.worldToLocalMatrix);
        mRaster.SetVector("voxelDim", vox_dim);
        mRaster.SetTexture("uavTex", uavTex3D);

        initialized = true;
        numFrames = 0;
    }

    private void OnPostRender()
    {
        if (DrawTechnique != null)
            DrawTechnique();
    }

    private void Update()
    {
        if (oneShot && numFrames > 0)
            return;

        SetView(Vector3.forward);
        DrawTechnique = ClearTechnique;
        cam.Render();

        if (StableRenderEntities != null && StableRenderEntities.Count > 0)
        {
            DrawTechnique = ConservativeGSTechnique;
            cam.Render();
        }

        if(FastRenderEntities != null && FastRenderEntities.Count > 0)
        {
            DrawTechnique = ConservativeVSTechnique;
            cam.Render();
            SetView(Vector3.up);
            cam.Render();
            SetView(Vector3.right);
            cam.Render();
        }

        if (OnReadyToUse != null)
            OnReadyToUse();

        ++numFrames;
    }

    private void OnDestroy()
    {
        if (mRaster != null)
            DestroyImmediate(mRaster);
        if (uavTex3D != null)
            DestroyImmediate(uavTex3D);
    }
}
