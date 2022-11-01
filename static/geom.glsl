#extension GL_EXT_gpu_shader4 : enable
layout (triangles) in;
layout (triangle_strip, max_vertices = 3) out;

in VS_OUT {
  vec3 FragPos;  
  vec3 Normal;
  vec2 TexCoord;
  vec4 eyespace;
} gs_in[];

out vec3 FragPos;  
out vec3 Normal;
out vec2 TexCoord;
out vec3 dist;
out vec4 eyespace;

uniform vec2 WIN_SCALE;

void main(void)
{
  vec2 p0 = WIN_SCALE * gl_in[0].gl_Position.xy/gl_in[0].gl_Position.w;
  vec2 p1 = WIN_SCALE * gl_in[1].gl_Position.xy/gl_in[1].gl_Position.w;
  vec2 p2 = WIN_SCALE * gl_in[2].gl_Position.xy/gl_in[2].gl_Position.w;
  
  vec2 v0 = p2-p1;
  vec2 v1 = p2-p0;
  vec2 v2 = p1-p0;
  float area = abs(v1.x*v2.y - v1.y* v2.x);

  dist = vec3(area/length(v0),0,0);
  gl_Position = gl_in[0].gl_Position;
  eyespace = gs_in[0].eyespace;
  FragPos = gs_in[0].FragPos;
  Normal = gs_in[0].Normal;
  TexCoord = gs_in[0].TexCoord;
  EmitVertex();
	
  dist = vec3(0,area/length(v1),0);
  gl_Position = gl_in[1].gl_Position;
  eyespace = gs_in[1].eyespace;
  FragPos = gs_in[1].FragPos;
  Normal = gs_in[1].Normal;
  TexCoord = gs_in[1].TexCoord;
  EmitVertex();

  dist = vec3(0,0,area/length(v2));
  gl_Position = gl_in[2].gl_Position;
  eyespace = gs_in[2].eyespace;
  FragPos = gs_in[2].FragPos;
  Normal = gs_in[2].Normal;
  TexCoord = gs_in[2].TexCoord;
  EmitVertex();

  EndPrimitive();
}
