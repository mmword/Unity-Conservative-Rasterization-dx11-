using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Rigidbody))]
public class MovedCamera : MonoBehaviour {

    public float MouseSpeedX = 1F;
    public float MouseSpeedY = 1F;
    Rigidbody body;

	// Use this for initialization
	void Start () {
        body = GetComponent<Rigidbody>();
	}
	
	// Update is called once per frame
	void Update () {

        if (Input.GetMouseButton(0))
        {
            Vector3 angles = transform.eulerAngles;
            angles.x += Input.GetAxis("Mouse Y") * MouseSpeedY * -1F;
            angles.y += Input.GetAxis("Mouse X") * MouseSpeedX;
            angles.z = 0;
            transform.eulerAngles = angles;
        }

        if (Input.GetKey(KeyCode.W))
            body.AddForce(transform.forward, ForceMode.VelocityChange);
        if (Input.GetKey(KeyCode.S))
            body.AddForce(transform.forward * -1F, ForceMode.VelocityChange);
        if (Input.GetKey(KeyCode.A))
            body.AddForce(transform.right * -1F, ForceMode.VelocityChange);
        if (Input.GetKey(KeyCode.D))
            body.AddForce(transform.right, ForceMode.VelocityChange);

    }
}
