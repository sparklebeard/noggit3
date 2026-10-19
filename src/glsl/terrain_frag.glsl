// This file is part of Noggit3, licensed under GNU General Public License (version 3). 
#version 410 core

struct chunk_shader_data
{
  bool has_shadow;
  bool is_textured;
  bool cant_paint;
  bool impassible_flag;

  vec3 tex_anim[4]; // direction + speed
  vec4 areaid_color;
  ivec4 tex_param_0;
  ivec4 tex_param_1;

  bool is_copied;
  bool is_in_paste_zone;
  bool pad_1;
  bool pad_2;
};

layout (std140) uniform chunk_data
{
  chunk_shader_data ubo_data[256];
};


// todo: move to opengl 4.1+ to be able to use the layout qualifier to be able to validate the program on creation
uniform sampler2DArray alphamap;
// set by the application from GL_MAX_TEXTURE_IMAGE_UNITS - 1 (alphamap uses unit 0)
#ifndef TEXTURE_ARRAY_COUNT
#define TEXTURE_ARRAY_COUNT 31
#endif
uniform sampler2DArray texture_arrays[TEXTURE_ARRAY_COUNT];


uniform bool show_selection_data;
uniform bool show_unpaintable_chunks;
uniform bool draw_impassible_flag;
uniform bool draw_areaid_overlay;
uniform bool draw_terrain_height_contour;
uniform bool draw_lines;
uniform bool draw_hole_lines;

uniform bool draw_shadows;
uniform bool draw_vertex_colors;

uniform bool draw_wireframe;
uniform int wireframe_type;
uniform float wireframe_radius;
uniform float wireframe_width;
uniform vec4 wireframe_color;
uniform bool rainbow_wireframe;

uniform vec3 camera;
uniform bool draw_fog;
uniform vec4 fog_color;
uniform float fog_start;
uniform float fog_end;

uniform bool draw_cursor_circle;
uniform bool draw_cursor_square;
uniform vec3 cursor_position;
uniform float outer_cursor_radius;
uniform float inner_cursor_ratio;
uniform vec4 cursor_color;

uniform vec3 light_dir;
uniform vec3 diffuse_color;
uniform vec3 ambient_color;

uniform float anim_time;


in vec3 vary_position;
in vec2 vary_texcoord;
in vec3 vary_normal;
in vec3 vary_mccv;

flat in int chunk_id;

out vec4 out_color;

const float TILESIZE  = 533.33333;
const float CHUNKSIZE = TILESIZE / 16.0;
const float HOLESIZE  = CHUNKSIZE * 0.25;
const float UNITSIZE = HOLESIZE * 0.5;

#define SAMPLE_TEXTURE_ARRAY(i) if (array_index == i) { return texture(texture_arrays[i], uv).rgb; }

// required because opengl can't handle non uniform index for uniform arrays
vec3 texture_color(int array_index, int index_in_array, vec2 anim_uv)
{
  vec3 uv = vec3(vary_texcoord + anim_uv, index_in_array);

  // opengl guarantees at least 16 texture units per shader stage
  SAMPLE_TEXTURE_ARRAY(0)
  SAMPLE_TEXTURE_ARRAY(1)
  SAMPLE_TEXTURE_ARRAY(2)
  SAMPLE_TEXTURE_ARRAY(3)
  SAMPLE_TEXTURE_ARRAY(4)
  SAMPLE_TEXTURE_ARRAY(5)
  SAMPLE_TEXTURE_ARRAY(6)
  SAMPLE_TEXTURE_ARRAY(7)
  SAMPLE_TEXTURE_ARRAY(8)
  SAMPLE_TEXTURE_ARRAY(9)
  SAMPLE_TEXTURE_ARRAY(10)
  SAMPLE_TEXTURE_ARRAY(11)
  SAMPLE_TEXTURE_ARRAY(12)
  SAMPLE_TEXTURE_ARRAY(13)
  SAMPLE_TEXTURE_ARRAY(14)
#if TEXTURE_ARRAY_COUNT > 15
  SAMPLE_TEXTURE_ARRAY(15)
#endif
#if TEXTURE_ARRAY_COUNT > 16
  SAMPLE_TEXTURE_ARRAY(16)
#endif
#if TEXTURE_ARRAY_COUNT > 17
  SAMPLE_TEXTURE_ARRAY(17)
#endif
#if TEXTURE_ARRAY_COUNT > 18
  SAMPLE_TEXTURE_ARRAY(18)
#endif
#if TEXTURE_ARRAY_COUNT > 19
  SAMPLE_TEXTURE_ARRAY(19)
#endif
#if TEXTURE_ARRAY_COUNT > 20
  SAMPLE_TEXTURE_ARRAY(20)
#endif
#if TEXTURE_ARRAY_COUNT > 21
  SAMPLE_TEXTURE_ARRAY(21)
#endif
#if TEXTURE_ARRAY_COUNT > 22
  SAMPLE_TEXTURE_ARRAY(22)
#endif
#if TEXTURE_ARRAY_COUNT > 23
  SAMPLE_TEXTURE_ARRAY(23)
#endif
#if TEXTURE_ARRAY_COUNT > 24
  SAMPLE_TEXTURE_ARRAY(24)
#endif
#if TEXTURE_ARRAY_COUNT > 25
  SAMPLE_TEXTURE_ARRAY(25)
#endif
#if TEXTURE_ARRAY_COUNT > 26
  SAMPLE_TEXTURE_ARRAY(26)
#endif
#if TEXTURE_ARRAY_COUNT > 27
  SAMPLE_TEXTURE_ARRAY(27)
#endif
#if TEXTURE_ARRAY_COUNT > 28
  SAMPLE_TEXTURE_ARRAY(28)
#endif
#if TEXTURE_ARRAY_COUNT > 29
  SAMPLE_TEXTURE_ARRAY(29)
#endif
#if TEXTURE_ARRAY_COUNT > 30
  SAMPLE_TEXTURE_ARRAY(30)
#endif

  return vec3(0.0);
}

vec2 anim_uv(int index)
{
  vec3 v = ubo_data[chunk_id].tex_anim[index];
  return v.xy * mod(anim_time * v.z, 1.);
}

vec4 texture_blend() 
{
  if(!ubo_data[chunk_id].is_textured)
    return vec4 (1.0, 1.0, 1.0, 1.0);

  vec3 alpha = texture(alphamap, vec3(vary_texcoord / 8., chunk_id + 0.1)).rgb;

  float a0 = alpha.r;
  float a1 = alpha.g;
  float a2 = alpha.b;

  ivec4 p0 = ubo_data[chunk_id].tex_param_0;
  ivec4 p1 = ubo_data[chunk_id].tex_param_1;

  vec3 t0 = texture_color(p0.x, p1.x, anim_uv(0));
  vec3 t1 = texture_color(p0.y, p1.y, anim_uv(1));
  vec3 t2 = texture_color(p0.z, p1.z, anim_uv(2));
  vec3 t3 = texture_color(p0.w, p1.w, anim_uv(3));

  return vec4 (t0 * (1.0 - (a0 + a1 + a2)) + t1 * a0 + t2 * a1 + t3 * a2, 1.0);
}

float contour_alpha(float unit_size, float pos, float line_width)
{
  float f = abs(fract((pos + unit_size*0.5) / unit_size) - 0.5);
  float df = abs(line_width / unit_size);
  return smoothstep(0.0, df, f);
}

float contour_alpha(float unit_size, vec2 pos, vec2 line_width)
{
  return 1.0 - min( contour_alpha(unit_size, pos.x, line_width.x)
                  , contour_alpha(unit_size, pos.y, line_width.y)
                  );
}

void main()
{
  float dist_from_camera = distance(camera, vary_position);

  if(draw_fog && dist_from_camera >= fog_end)
  {
    out_color = fog_color;
    return;
  } 
  vec3 fw = fwidth(vary_position.xyz);

  out_color = texture_blend();

  if(draw_vertex_colors)
  {
    out_color.rgb *= vary_mccv;
  }

  // diffuse + ambient lighting
  out_color.rgb *= vec3(clamp (diffuse_color * max(dot(vary_normal, light_dir), 0.0), 0.0, 1.0)) + ambient_color;

  if(show_unpaintable_chunks && ubo_data[chunk_id].cant_paint)
  {
    out_color *= vec4(1.0, 0.0, 0.0, 1.0);
  }
  
  if(draw_areaid_overlay)
  {
    out_color = out_color * 0.3 + ubo_data[chunk_id].areaid_color;
  }

  if(draw_impassible_flag && ubo_data[chunk_id].impassible_flag)
  {
    out_color.rgb = mix(vec3(1.0), out_color.rgb, 0.5);
  }

  if(ubo_data[chunk_id].has_shadow && draw_shadows)
  {
    out_color = vec4 (out_color.rgb * (1.0 - texture(alphamap, vec3(vary_texcoord / 8.0, chunk_id + 0.1)).a * 0.333) , 1.0);
  }  

  if (draw_terrain_height_contour)
  {
    out_color = vec4(out_color.rgb * contour_alpha(4.0, vary_position.y+0.1, fw.y), 1.0);
  }

  if(show_selection_data)
  { 
    if(ubo_data[chunk_id].is_copied && ubo_data[chunk_id].is_in_paste_zone)
    {
      out_color.rgb = mix(out_color.rgb, vec3(0.8, 0.3, 0.8), 0.5);
    }
    else if(ubo_data[chunk_id].is_copied)
    {
      out_color.rgb = mix(out_color.rgb, vec3(0.4, 0.95, 0.3), 0.5);
    }
    else if(ubo_data[chunk_id].is_in_paste_zone)
    {
      out_color.rgb = mix(out_color.rgb, vec3(0.34, 0.6, 0.9), 0.5);
    }
  }

  bool lines_drawn = false;
  if(draw_lines)
  {
    vec4 color = vec4(0.0, 0.0, 0.0, 0.0);

    color.a = contour_alpha(TILESIZE, vary_position.xz, fw.xz * 1.5);
    color.g = color.a > 0.0 ? 0.8 : 0.0;

    if(color.a == 0.0)
    {
      color.a = contour_alpha(CHUNKSIZE, vary_position.xz, fw.xz);
      color.r = color.a > 0.0 ? 0.8 : 0.0;
    }
    if(draw_hole_lines && color.a == 0.0)
    {
      color.a = contour_alpha(HOLESIZE, vary_position.xz, fw.xz * 0.75);
      color.b = 0.8;
    }
    
    lines_drawn = color.a > 0.0;
    out_color.rgb = mix(out_color.rgb, color.rgb, color.a);
  }

  if(draw_fog && dist_from_camera >= fog_end * fog_start)
  {
    float start = fog_end * fog_start;
    float alpha = (dist_from_camera - start) / (fog_end - start);
    out_color.rgb = mix(out_color.rgb, fog_color.rgb, alpha);
  }

  if(draw_wireframe && !lines_drawn)
  {
    // true by default => type 0
	  bool draw_wire = true;
    float real_wireframe_radius = max(outer_cursor_radius * wireframe_radius, 2.0 * UNITSIZE); 
	
	  if(wireframe_type == 1)
	  {
		  draw_wire = (length(vary_position.xz - cursor_position.xz) < real_wireframe_radius);
	  }
	
	  if(draw_wire)
	  {
		  float alpha = contour_alpha(UNITSIZE, vary_position.xz, fw.xz * wireframe_width);
		  float xmod = mod(vary_position.x, UNITSIZE);
		  float zmod = mod(vary_position.z, UNITSIZE);
		  float d = length(fw.xz) * wireframe_width;
		  float diff = min( min(abs(xmod - zmod), abs(xmod - UNITSIZE + zmod))
                      , min(abs(zmod - xmod), abs(zmod + UNITSIZE - zmod))
                      );        

		  alpha = max(alpha, 1.0 - smoothstep(0.0, d, diff));
      out_color.rgb = mix(out_color.rgb, wireframe_color.rgb, wireframe_color.a*alpha);
	  }
  }

  if (draw_cursor_circle)
  {
    float diff = length(vary_position.xz - cursor_position.xz);
    diff = min(abs(diff - outer_cursor_radius), abs(diff - outer_cursor_radius * inner_cursor_ratio));
    float alpha = smoothstep(0.0, length(fw.xz), diff);

    out_color.rgb = mix(cursor_color.rgb, out_color.rgb, alpha);
  }
  if(draw_cursor_square)
  {
    // SDF box formula
    vec2 p = abs(vary_position.xz - cursor_position.xz);
    vec2 d = p - vec2(outer_cursor_radius, outer_cursor_radius);
    float dist = length(max(d,0.0)) + min(max(d.x,d.y),0.0);
    // abs(dist) to get only the border
    float alpha = smoothstep(0., length(fw.xz), abs(dist));

    out_color.rgb = mix(cursor_color.rgb, out_color.rgb, alpha);
  }
}
