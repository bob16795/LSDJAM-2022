out vec4 FragColor;

in vec3 FragPos;  
in vec3 Normal;
in vec2 TexCoord;
in vec3 dist;
in vec4 eyespace;

uniform sampler2D tex;
uniform sampler2D texuv;
uniform float brightness;
uniform vec4 fogColor;
uniform float fogDensity;

float getFogFactor(float fogCoordinate)
{
	float result = 0.0;
    result = exp(-pow(fogDensity * fogCoordinate, 2.0));
	
	result = 1.0 - clamp(result, 0.0, 1.0);
	return result;
}

void main()
{
    vec2 size = vec2(32, 98);

    vec2 nearest = vec2(floor((TexCoord.x*(size.x-1)+0.5))/(size.x-1), floor((TexCoord.y*(size.y-1)+0.5))/(size.y-1));

    vec4 texture = texture2D(tex, nearest);

    FragColor = mix(texture, vec4(0.1, 0.1, 0.1, 1.0), brightness);
    FragColor.rgb = mix(FragColor.rgb, fogColor.rgb, getFogFactor(eyespace.z / eyespace.w));
} 

