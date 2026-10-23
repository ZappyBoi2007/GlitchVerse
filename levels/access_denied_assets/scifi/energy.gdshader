shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 tint : source_color = vec4(0.03,0.7,1.0,0.65);
void fragment(){
float scan=0.7+0.3*sin(UV.y*100.0-TIME*2.0);
float edge=pow(abs(UV.x-0.5)*2.0,8.0);
ALBEDO=tint.rgb*(scan+edge); ALPHA=tint.a;
}
