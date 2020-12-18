precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>
uniform vec3 uBallPos;
uniform vec3 uPlayerPos;
uniform vec3 uComputerPos;
uniform vec3 uHalfRoomDimensions;
uniform float uPaddleRadX;
uniform float uPaddleRadY;
uniform bool uCutSceneIsPlaying;

#define N_SPHERES 1
#define N_PLANES 5
#define N_BOXES 6
#define N_QUADS 1


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Plane { vec4 pla; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Plane planes[N_PLANES];
Box boxes[N_BOXES];
Quad quads[N_QUADS];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_single_sided_plane_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_sample_quad_light>

#include <pathtracing_sample_sphere_light>



//--------------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//--------------------------------------------------------------------------
{
	vec3 n;
	float d = INFINITY;
	float t = INFINITY;
	bool isRayExiting = false;
	
        for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize((r.origin + r.direction * t) - spheres[i].position);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
		}
	}

	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, r, false);
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(quads[i].normal);
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
		}
	}

	for (int i = 0; i < N_PLANES; i++)
        {
		d = SingleSidedPlaneIntersect( planes[i].pla, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(planes[i].pla.xyz);
			intersec.emission = planes[i].emission;
			intersec.color = planes[i].color;
			intersec.type = planes[i].type;
		}
        }

	for (int i = 0; i < N_BOXES; i++)
        {
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, r, n, isRayExiting );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(n);
			intersec.emission = boxes[i].emission;
			intersec.color = boxes[i].color;
			intersec.type = boxes[i].type;
			//finalIsRayExiting = isRayExiting;
		}
        }
	

	return t;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance(Ray r, out bool surfaceIsDynamic)
//-----------------------------------------------------------------------
{
	Intersection intersec;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool lastHitWasSpec = false;
	surfaceIsDynamic = true;

	
	for (int bounces = 0; bounces < 6; bounces++)
	{

		t = SceneIntersect(r, intersec);
		
		
		if (t == INFINITY)
			break;
		
		
		if (intersec.type == LIGHT)
		{	
			if (sampleLight)
				accumCol = mask * intersec.emission;
			else if (bounceIsSpecular)
			{
				accumCol = mask * clamp(intersec.emission, 0.0, 1.0);
				if (intersec.emission == vec3(10.0))
					surfaceIsDynamic = true;
			}
				
			// reached a light, so we can exit
			break;
		}


		//if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 
			break;
		

		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? n : normalize(-n);
		x = r.origin + r.direction * t;

		// make player's background mirror reflection a solid plastic surface 
		if (lastHitWasSpec && intersec.type == REFR)
			intersec.type = COAT;

		 
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			surfaceIsDynamic = false;

			diffuseCount++;

			mask *= intersec.color;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			if (diffuseCount == 1)
				dirToLight = sampleSphereLight(x, nl, spheres[0], weight);
			else
				dirToLight = sampleQuadLight(x, nl, quads[0], weight);	
				
			mask *= weight;

			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} // end if (intersec.type == DIFF)
		
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			lastHitWasSpec = true;

			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;

			continue;
		}

		

		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);
			
			if (rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			mask *= intersec.color;
			mask *= TP;
			
			//tdir = refract(r.direction, nl, ratioIoR);
			tdir = r.direction;
			r = Ray(x, tdir);
			r.origin -= nl * uEPS_intersect;

			// if (diffuseCount == 1)
			// 	bounceIsSpecular = true; // turn on refracting caustics

			continue;
			
		} // end if (intersec.type == REFR)

		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			surfaceIsDynamic = (bounces == 0 && intersec.color == vec3(0.7, 0.1, 1.0));

			if (rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;

			mask *= TP;
			mask *= intersec.color;
			
			bounceIsSpecular = false;
			
			// if (diffuseCount == 1 && rand() < 0.5)
			// {
			// 	// choose random Diffuse sample vector
			// 	r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
			// 	r.origin += nl * uEPS_intersect;
			// 	continue;
			// }

			if (distance(x, uBallPos) < rand() * 100.0 && rand() < dot(nl, normalize(uBallPos - x)))
				dirToLight = sampleSphereLight(x, nl, spheres[0], weight);
			else
				dirToLight = sampleQuadLight(x, nl, quads[0], weight);

			mask *= weight;
			
			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
			
		} //end if (intersec.type == COAT)
		

	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance(Ray r)



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 0.7, 0.4) * 12.0;// Bright light
	float lightY = uHalfRoomDimensions.y - 3.0;

	spheres[0] = Sphere( 5.0, uBallPos, vec3(10.0), z, LIGHT);// Game Ball

	planes[0] = Plane( vec4( 0,0,1, -uHalfRoomDimensions.z), z, vec3(0.1), SPEC);// Back Wall Plane
	planes[1] = Plane( vec4( 0,-1,0, -uHalfRoomDimensions.y), z, vec3(0.2), DIFF);// Ceiling Plane
	planes[2] = Plane( vec4( 0,1,0, -uHalfRoomDimensions.y), z, vec3(1.0), COAT);// Floor Plane
	planes[3] = Plane( vec4( 1,0,0, -uHalfRoomDimensions.x), z, vec3(1.0, 0.0 ,0.0), COAT);// Red Left Wall Plane
	planes[4] = Plane( vec4(-1,0,0, -uHalfRoomDimensions.x), z, vec3(0.0, 0.7, 0.0), COAT);// Green Right Wall Plane
	//planes[5] = Plane( vec4( 0,0,-1, -uHalfRoomDimensions.z), z, vec3(0.1), SPEC);// Front Wall Plane (behind camera)

	boxes[0] = Box( vec3(-uHalfRoomDimensions.x + 1.0, uBallPos.y - 5.0, uBallPos.z - 10.0), vec3(-uHalfRoomDimensions.x + 2.0, uBallPos.y + 5.0, uBallPos.z + 10.0), z, vec3(1.0, 0.765557, 0.336057), SPEC);// Gold Metal Box left
	boxes[1] = Box( vec3( uHalfRoomDimensions.x - 2.0, uBallPos.y - 5.0, uBallPos.z - 10.0), vec3( uHalfRoomDimensions.x - 1.0, uBallPos.y + 5.0, uBallPos.z + 10.0), z, vec3(1.0), SPEC);// Aluminum Metal Box right
	boxes[2] = Box( vec3(uBallPos.x - 5.0, uHalfRoomDimensions.y - 2.0, uBallPos.z - 10.0), vec3(uBallPos.x + 5.0, uHalfRoomDimensions.y - 1.0, uBallPos.z + 10.0), z, vec3(0.955008, 0.637427, 0.538163), SPEC);// Copper Metal Box ceiling
	boxes[3] = Box( vec3(uBallPos.x - 5.0, -uHalfRoomDimensions.y + 1.0, uBallPos.z - 10.0), vec3(uBallPos.x + 5.0, -uHalfRoomDimensions.y + 2.0, uBallPos.z + 10.0), z, vec3(0.955008, 0.637427, 0.538163), SPEC);// Copper Metal Box floor
	boxes[4] = Box( vec3(uPlayerPos.x-uPaddleRadX, uPlayerPos.y-uPaddleRadY, uPlayerPos.z), vec3(uPlayerPos.x+uPaddleRadX, uPlayerPos.y+uPaddleRadY, uPlayerPos.z+3.0), z, vec3(0.1, 0.7, 1.0), uCutSceneIsPlaying ? COAT : REFR);// Player paddle
	boxes[5] = Box( vec3(uComputerPos.x-uPaddleRadX, uComputerPos.y-uPaddleRadY, uComputerPos.z), vec3(uComputerPos.x+uPaddleRadX, uComputerPos.y+uPaddleRadY, uComputerPos.z+3.0), z, vec3(0.7, 0.1, 1.0), COAT);// Computer A.I. paddle

	quads[0] = Quad( vec3(0,-1, 0), vec3(-10,lightY,-10), vec3(10,lightY,-10), vec3(10,lightY,10), vec3(-10,lightY,10), L1, z, LIGHT);// rectangular Area Light in ceiling
}


//#include <pathtracing_main>

// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}


void main( void )
{
	// not needed, three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	
	// calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord); // old way of generating random numbers

	randVec4 = texture(tBlueNoiseTexture, (gl_FragCoord.xy + (uRandomVec2 * 255.0)) / 255.0); // new way of rand()
	
	//vec2 pixelOffset = vec2( tentFilter(rng()), tentFilter(rng()) ) * 0.5;
	// even though it is ultimately set to 0.0, the following is needed to avoid artifacts on mobile. :-/ ?
	vec2 pixelOffset = vec2(tentFilter(uRandomVec2.x)) * 0.0;

	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = (gl_FragCoord.xy + pixelOffset) / uResolution.xy * 2.0 - 1.0;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	/* 
	// depth of field (not used in this game)
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand() * TWO_PI; // pick random point on aperture
	float randomRadius = rand() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir ); 
	*/

	Ray ray = Ray(cameraPosition, rayDir);

	SetupScene(); 
	
	bool surfaceIsDynamic = true;
	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance(ray, surfaceIsDynamic);
	
	vec4 previousPixelData = texelFetch(tPreviousTexture, ivec2(gl_FragCoord), 0);
	vec3 previousColor = previousPixelData.rgb;

	
	if (previousPixelData.a < 1.0 || surfaceIsDynamic)
	{
                previousColor *= 0.0; // motion-blur trail amount (old image)
                //pixelColor *= 1.0; // brightness of new image (noisy)
        }
	else if (uCameraIsMoving)
	{
                previousColor *= 0.6; // motion-blur trail amount (old image)
                pixelColor *= 0.4; // brightness of new image (noisy)
        }
	else
	{
                previousColor *= 0.9; // motion-blur trail amount (old image)
                pixelColor *= 0.1; // brightness of new image (noisy)
        }
	
        pc_fragColor = vec4( pixelColor + previousColor, surfaceIsDynamic ? 0.99 : 1.0 );	
}