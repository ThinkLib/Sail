//lambertian

struct Lambertian{
    float kd;
    vec3 cd;
};

vec3 lambertian_f(Lambertian l,const vec3 wi,const vec3 wo){
    return l.kd * l.cd * INVPI;
}

vec3 lambertian_sample_f(Lambertian l,float seed,out vec3 wi, vec3 wo, out float pdf){
	wi = cosWeightHemisphere(seed);
	pdf = INVPI;
	return lambertian_f(l,wi,wo);
}

//reflective

struct Reflective{
    float kr;
    vec3 cr;
};

vec3 reflective_f(Reflective r,const vec3 wi,const vec3 wo){
    return BLACK;
}

vec3 reflective_sample_f(Reflective r,float seed,out vec3 wi, vec3 wo, out float pdf){
	wi = vec3(-wo.x,-wo.y,wo.z) + uniformlyRandomVector(seed) * (1.0-r.kr);
	pdf = 1.0;
	return r.cr;
}


//ward

struct Ward{
    float ax, ay;
    float invax2, invay2;
    float const2;
    vec3 rs;
};

vec3 ward_f(Ward w,const vec3 wi,const vec3 wo){
//  vec3 H = wi+wo;
//  vec3 specular = w.rs;
//	float const1 = wi.z*wo.z;
//	if(const1 <= 0.f) return specular;
//	const1 = inversesqrt(const1);
//	float const3 = exp(-1.f * (H.x*H.x*w.invax2 + H.y*H.y*w.invay2)/(H.z*H.z));
//	specular = w.rs * const3 * const1 / w.const2;
    return w.rs;
}

vec3 ward_sample_f(Ward w,float seed,out vec3 wi, vec3 wo, out float pdf){
    vec3 h;
    float u1 = random( vec3( 12.9898, 78.233, 151.7182 ), seed );
    float u2 = random( vec3( 63.7264, 10.873, 623.6736 ), seed );
	float phi = atan(w.ay*tan(2.0*PI*u2),w.ax);
	float cosPhi = cos(phi);
	float sinPhi = sqrt(1.0-cosPhi*cosPhi);
	float theta = atan(sqrt(-log(u1)/(cosPhi*cosPhi*w.invax2 + sinPhi*sinPhi*w.invay2)));

	h.z = cos(theta);
	float cosTheta2 = h.z*h.z;
	float sinTheta = sqrt(1.0-cosTheta2);
	float tanTheta2 = (1.0-cosTheta2)/cosTheta2;
	h.x = cosPhi*sinTheta;
	h.y = sinPhi*sinTheta;

	if(dot(wo,h)<-EPSILON) h=-h;
	wi = -wo + 2.f * dot(wo, h) * h;
	pdf = 1.0;//exp(-tanTheta2*(cosPhi*cosPhi*w.invax2 + sinPhi*sinPhi*w.invay2))/(w.const2*dot(h,wo)*cosTheta2*h.z);
	return ward_f(w,wi,wo);
}

//refractive

struct Refractive{
    vec3 rc;
    float F0;
    float nt;
};

vec3 refractive_f(Refractive r,vec3 wi, vec3 wo){
    return BLACK;
}

vec3 refractive_sample_f(Refractive r,float seed,bool into,out vec3 wi, vec3 wo, out float pdf){
    float u = random( vec3( 12.9898, 78.233, 151.7182 ), seed );
    vec3 n = vec3(0.0,0.0,1.0);
    float nnt = into ? NC / r.nt : r.nt / NC;
    float ddn = dot(-wo,n);

	vec3 refr = refract(-wo,n,nnt);

	float c = 1.0-(into?-ddn:dot(-n,refr));
    float Fe = r.F0 + (1.0 - r.F0) * c * c * c * c * c;
    float Fr = 1.0 - Fe;
    pdf = 0.25 + 0.5 * Fe;
    if (u < pdf){
        wi = vec3(-wo.x,-wo.y,wo.z);
        return r.rc * Fe;
    }
    else{
        wi = refr;
        pdf = 1.0-pdf;
        return r.rc * Fr;
    }
}


