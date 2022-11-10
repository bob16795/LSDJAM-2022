layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoord;

out VS_OUT {
  vec3 FragPos;  
  vec3 Normal;
  vec2 TexCoord;
  vec4 eyespace;
} vs_out;

uniform mat4 view;
uniform mat4 proj;
uniform mat4 model;
uniform mat4 shift;

void main()
{
    vs_out.FragPos = (shift * model * vec4(aPos, 1.0)).xyz;
    
    vs_out.eyespace = view * shift * model * vec4(aPos, 1.0);

    gl_Position = proj * view * shift * model * vec4(aPos, 1.0);

    vs_out.TexCoord = aTexCoord;
    vs_out.Normal = aNormal;
}
