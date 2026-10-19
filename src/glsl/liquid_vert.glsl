// This file is part of Noggit3, licensed under GNU General Public License (version 3).
#version 410 core
// use_draw_parameters is defined by the application when the extension is supported
// otherwise (eg: macOS) each chunk is drawn separately and its id is set with draw_id_fallback
#ifdef use_draw_parameters
#extension GL_ARB_shader_draw_parameters : require
#endif

in vec4 position;
in vec2 tex_coord;
in float depth;

uniform mat4 model_view;
uniform mat4 projection;
uniform mat4 transform;

uniform int use_transform = int(0);

#ifndef use_draw_parameters
uniform int draw_id_fallback;
#endif

out vec3 f_position;
out float depth_;
out vec2 tex_coord_;
flat out int draw_id;

void main()
{
  f_position = position.xyz;
  depth_ = depth;
  tex_coord_ = tex_coord;

  if(use_transform == 1)
  {
    gl_Position = projection * model_view * transform * position;
    draw_id = 0;
  }
  else
  {
    gl_Position = projection * model_view * position;
#ifdef use_draw_parameters
    draw_id = gl_DrawIDARB;
#else
    draw_id = draw_id_fallback;
#endif
  }
}
