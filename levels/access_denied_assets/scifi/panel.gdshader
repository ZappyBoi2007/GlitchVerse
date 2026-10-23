shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.17,0.23,0.3,1.0);
uniform vec4 accent : source_color = vec4(0.05,0.75,0.95,1.0);
uniform float panel_scale = 1.0;
uniform float metal = 0.55;
varying vec3 wp;
varying vec3 wn;
void vertex(){ wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; wn=normalize(MODEL_NORMAL_MATRIX*NORMAL); }
void fragment(){
vec3 n=abs(wn);
vec2 uv=wp.xz;
if(n.x>n.y && n.x>n.z){uv=wp.zy;}
else if(n.z>n.y){uv=wp.xy;}
vec2 f=fract(uv*panel_scale);
float seam=step(0.975,max(f.x,f.y));
float stripe=step(0.94,f.x)*step(f.x,0.96)*step(0.18,f.y)*step(f.y,0.45);
float grain=sin(uv.x*310.0)*sin(uv.y*273.0)*0.008;
ALBEDO=mix(base_color.rgb+grain,base_color.rgb*0.25,seam);
METALLIC=metal; ROUGHNESS=0.55;
EMISSION=accent.rgb*stripe*0.6;
}
