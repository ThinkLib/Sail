#include "bsdfs.glsl"
#include "../const/ray.glsl"

void matte_attr(float matIndex,out float kd){
    kd = readFloat(texParams,vec2(1.0,matIndex),TEX_PARAMS_LENGTH);
}

vec3 matte(Intersect ins,inout Ray ray){
    vec3 wo = -ray.dir;
    vec3 wi,f;
    float pdf;
    vec3 sdir,tdir;
    float kd;
    matte_attr(ins.matIndex,kd);
    getCoordinate(ins.normal,sdir,tdir);
    wo = toLocalityCoordinate(sdir,tdir,ins.normal,wo);

    Lambertian diffuse_brdf = Lambertian(kd,ins.sc);
    f = lambertian_sample_f(diffuse_brdf,ins.seed,wi,wo,pdf);

    wi = toWorldCoordinate(sdir,tdir,ins.normal,wi);

    ray = Ray(ins.hit,wi);
    float ndotwi = max(dot(ins.normal,wi),0.0);
    return f*ndotwi/pdf;
}