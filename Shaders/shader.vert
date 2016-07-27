#version 430 core

layout(location = 0) in vec4 vPosition;
layout(location = 2) in vec2 uvCoords;

uniform vec4 mwc1;
uniform vec4 mwc2;
uniform vec4 mwc3;
uniform vec4 mwc4;

uniform vec4 col;
uniform vec4 pos;

// Output data ; will be interpolated for each fragment.
out vec2 fragCoord;

varying vec4 fcol;

void main()
{
  mat4 mwm = mat4(mwc1,mwc2,mwc3,mwc4);
  gl_Position = mwm * vPosition;

// The color of each vertex will be interpolated
// to produce the color of each fragment
	 fragCoord = uvCoords;

   fcol = col;
}
