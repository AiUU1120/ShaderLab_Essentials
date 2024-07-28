using UnityEditor;
using UnityEngine;

namespace Editor
{
    /// <summary>
    /// 编辑器拓展 生成立方体纹理
    /// </summary>
    public sealed class RenderToCubeMapWindow : EditorWindow
    {
        private GameObject m_Obj;

        private Cubemap m_Cubemap;

        [MenuItem("立方体纹理动态生成/打开生成窗口")]
        static void OpenWindow()
        {
            var window = GetWindow<RenderToCubeMapWindow>("立方体纹理生成窗口");
            window.Show();
        }

        private void OnGUI()
        {
            GUILayout.Label("关联对应位置对象");
            m_Obj = EditorGUILayout.ObjectField(m_Obj, typeof(GameObject), true) as GameObject;
            GUILayout.Label("关联对应立方体纹理");
            m_Cubemap = EditorGUILayout.ObjectField(m_Cubemap, typeof(Cubemap), false) as Cubemap;
            if (GUILayout.Button("生成立方体纹理"))
            {
                if (m_Obj == null || m_Cubemap == null)
                {
                    EditorUtility.DisplayDialog("提醒", "请先关联对应对象和立方体贴图", "确认");
                    return;
                }
                // 动态生成立方体纹理
                var tmpObj = new GameObject("临时对象")
                {
                    transform =
                    {
                        position = m_Obj.transform.position
                    }
                };
                var camera = tmpObj.AddComponent<Camera>();
                // 关键方法 马上生成6张2D纹理贴图
                camera.RenderToCubemap(m_Cubemap);
                DestroyImmediate(tmpObj);
            }
        }
    }
}