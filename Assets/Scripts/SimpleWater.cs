using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleWater : MonoBehaviour {
    MeshRenderer mr;
    MeshFilter mf;
    Mesh mesh;

    public float quadWidth = 2;
    public float quadHeight = 2;
    public int quadRowCount = 1;
    public int quadColumnCount = 1;

    // Use this for initialization
    void Start () {
        mr = GetComponent<MeshRenderer>();
        mf = GetComponent<MeshFilter>();

        GernerateMesh();
        tempMPB = new MaterialPropertyBlock();
	}
	
    void GernerateMesh()
    {
        mf.mesh = new Mesh();
        mesh = mf.mesh;

        int vertexCount = (quadRowCount + 1) * (quadColumnCount + 1);
        int indexCount = 6 * quadColumnCount * quadRowCount;

        Vector3[] vertices = new Vector3[vertexCount];
        Color[] colors = new Color[vertexCount];

        int[] triangles = new int[indexCount];


        float halfTotalWidth = quadWidth * quadColumnCount / 2;
        float halfTotalHeight = quadHeight * quadRowCount / 2;

        for(int i = 0; i < quadRowCount + 1;i ++)
        {
            for (int j = 0; j < quadRowCount + 1; j++)
            {
                vertices[i * (quadColumnCount + 1) + j] = new Vector3(j * quadWidth - halfTotalWidth, 0, i * quadHeight - halfTotalHeight);

                float lerpX = (float)i / quadRowCount;
                float lerpY = (float)j / quadColumnCount;

                colors[i * quadColumnCount + j] = Color.Lerp(Color.Lerp(Color.blue, Color.red, lerpX), Color.Lerp(Color.yellow, Color.white, lerpX), lerpY);

                if(i != quadRowCount && j != quadColumnCount)
                {
                    int vertIndex = (i * (quadColumnCount + 1) + j);
                    int triVertIndex = (i * (quadColumnCount + 1) * 6);

                    triangles[triVertIndex] = vertIndex;
                    triangles[triVertIndex + 1] = vertIndex + quadColumnCount + 1;
                    triangles[triVertIndex + 2] = vertIndex + 1;

                    triangles[triVertIndex + 3] = vertIndex + quadColumnCount + 1;
                    triangles[triVertIndex + 4] = vertIndex + quadColumnCount + 2;
                    triangles[triVertIndex] = vertIndex + 1;
                }
            }
        }

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.colors = colors;
    }

    // Update is called once per frame
    void Update () {
        UpdatePara();
	}

    public float angleFreq = 1;
    public float waveLength = 1;
    public float amplitude = 1;
    public float Fresnel_0 = 0.020320f;

    MaterialPropertyBlock tempMPB;
    void UpdatePara()
    {
        tempMPB.Clear();
        tempMPB.SetFloat("angleFreq", angleFreq);
        tempMPB.SetFloat("waveLength", waveLength);
        tempMPB.SetFloat("amplitude", amplitude);
        tempMPB.SetFloat("Fresnel_0", Fresnel_0);

        mr.SetPropertyBlock(tempMPB);
    }
}
