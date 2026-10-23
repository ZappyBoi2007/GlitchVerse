shader_type sky;
float hash(vec3 p){return fract(sin(dot(p,vec3(12.9898,78.233,45.164)))*43758.5453);}
void sky(){
vec3 p=normalize(EYEDIR);
vec3 cell=floor(p*650.0);
float star=step(0.9988,hash(cell));
float haze=pow(max(0.0,1.0-abs(p.y+0.12)),10.0);
COLOR=mix(vec3(0.008,0.016,0.045),vec3(0.025,0.07,0.14),haze)+star*vec3(0.55,0.68,0.85);
}
