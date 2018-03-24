using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class DrawGizmos : MonoBehaviour {
    public bool DrawAtStart = false;
    public bool Draw = true;
    private void OnDrawGizmos()
    {
        if (Draw)
        {
            if (DrawAtStart)
                Gizmos.DrawWireCube(transform.position + transform.localScale * 0.5F, transform.localScale);
            else
                Gizmos.DrawWireCube(transform.position, transform.localScale);
        }
    }

}
