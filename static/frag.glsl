out vec4 FragColor;

in vec3 FragPos;  
in vec3 Normal;
in vec2 TexCoord;
in vec3 dist;
in vec4 eyespace;

uniform sampler2D tex;
uniform float brightness;

float getFogFactor(float fogCoordinate)
{
	float result = 0.0;
    result = exp(-pow(0.05 * fogCoordinate, 2.0));
	
	result = 1.0 - clamp(result, 0.0, 1.0);
	return result;
}

void main()
{
    vec4 texture = texture2D(tex, TexCoord);

    FragColor = mix(texture, vec4(0.1, 0.1, 0.1, 1.0), brightness);
    FragColor.rgb = mix(FragColor.rgb, vec3(0.569, 0.569, 1.0), getFogFactor(eyespace.z / eyespace.w));
} 

