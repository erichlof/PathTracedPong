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



//---------------------------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec, out float intersectedObjectID )
//---------------------------------------------------------------------------------------
{
	vec3 n;
	float d = INFINITY;
	float t = INFINITY;
	int objectCount = 0;
	bool isRayExiting = false;
	
	
	d = SphereIntersect( spheres[0].radius, spheres[0].position, r );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize((r.origin + r.direction * t) - spheres[0].position);
		intersec.emission = spheres[0].emission;
		intersec.color = spheres[0].color;
		intersec.type = spheres[0].type;
		intersectedObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, r, false);
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(quads[0].normal);
		intersec.emission = quads[0].emission;
		intersec.color = quads[0].color;
		intersec.type = quads[0].type;
		intersectedObjectID = float(objectCount);
	}
	objectCount++;

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
			intersectedObjectID = float(objectCount);
		}
		objectCount++;
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
			intersectedObjectID = float(objectCount);
		}
		objectCount++;
        }
	

	return t;
}


//--------------------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness, out float dynamicSurface )
//--------------------------------------------------------------------------------------------------------------------------------------------------
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
	float intersectedObjectID;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	intersec.type = -100;

	bool coatTypeIntersected = false;
	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool lastHitWasSpec = false;

	dynamicSurface = 0.0;

	
	for (int bounces = 0; bounces < 6; bounces++)
	{
		previousIntersecType = intersec.type;

		t = SceneIntersect(r, intersec, intersectedObjectID);
		
		
		if (t == INFINITY)
			break;

		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;

		if (bounces == 0)
		{
			objectNormal = nl;
			objectColor = intersec.color;
			objectID = intersectedObjectID;
		}
		
		
		if (intersec.type == LIGHT)
		{	
			if (diffuseCount == 0)
			{
				pixelSharpness = 1.01;

				if (intersec.emission == vec3(10))
					dynamicSurface = 1.0;
			}

			if (sampleLight)
				accumCol = mask * intersec.emission;
			else if (bounceIsSpecular)
			{
				accumCol = mask * clamp(intersec.emission, 0.0, 1.0);
			}
				
			// reached a light, so we can exit
			break;
		}


		//if we get here and sampleLight is still true, shadow ray failed to find a light source
		// if (sampleLight) 
		// 	break;
		

		// make player's background mirror reflection a solid plastic surface 
		if (lastHitWasSpec && intersec.type == REFR)
			intersec.type = COAT;

		 
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
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
			// if (distance(x, uBallPos) < rng() * 100.0 && rng() < dot(nl, normalize(uBallPos - x)))
			// 	dirToLight = sampleSphereLight(x, nl, spheres[0], weight);
			// else
			// 	dirToLight = sampleQuadLight(x, nl, quads[0], weight);
				
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
			if (diffuseCount == 0)
				pixelSharpness = -1.0;

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
			coatTypeIntersected = true;

			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(r.direction, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			if (intersec.color == vec3(0.7, 0.1, 1.0) && (bounces == 0 || previousIntersecType == REFR))
			{
				dynamicSurface = 1.0;
			}

			if (rand() < P)
			{
				if (diffuseCount == 0)
					pixelSharpness = -1.0;

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

			if (distance(x, uBallPos) < rng() * 100.0 && rand() < dot(nl, normalize(uBallPos - x)))
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
	vec3 L1 = vec3(1.0, 0.7, 0.4) * 30.0;// Bright light
	float lX = 10.0;
	float lY = uHalfRoomDimensions.y - 3.0;
	float lZ = 10.0;

	spheres[0] = Sphere( 5.0, uBallPos, vec3(10), z, LIGHT);// Game Ball

	planes[0] = Plane( vec4( 0,0,1, -uHalfRoomDimensions.z), z, vec3(0.1), SPEC);// Back Wall mirror
	planes[1] = Plane( vec4( 0,-1,0, -uHalfRoomDimensions.y), z, vec3(0.1), DIFF);// Ceiling (0.1)
	planes[2] = Plane( vec4( 0,1,0, -uHalfRoomDimensions.y), z, vec3(0.9), COAT);// Floor (0.9)
	planes[3] = Plane( vec4( 1,0,0, -uHalfRoomDimensions.x), z, vec3(1.0, 0.0 ,0.0), COAT);// Red Left Wall (1.0, 0.0 ,0.0)
	planes[4] = Plane( vec4(-1,0,0, -uHalfRoomDimensions.x), z, vec3(0.0, 0.7, 0.0), COAT);// Green Right Wall (0.0, 0.7, 0.0)
	//planes[5] = Plane( vec4( 0,0,-1, -uHalfRoomDimensions.z), z, vec3(0.1), SPEC);// Front Wall (behind camera)

	boxes[0] = Box( vec3(-uHalfRoomDimensions.x + 1.0, uBallPos.y - 5.0, uBallPos.z - 10.0), vec3(-uHalfRoomDimensions.x + 2.0, uBallPos.y + 5.0, uBallPos.z + 10.0), z, vec3(1.0, 0.765557, 0.336057), SPEC);// Gold Metal Box left
	boxes[1] = Box( vec3( uHalfRoomDimensions.x - 2.0, uBallPos.y - 5.0, uBallPos.z - 10.0), vec3( uHalfRoomDimensions.x - 1.0, uBallPos.y + 5.0, uBallPos.z + 10.0), z, vec3(1.0), SPEC);// Aluminum Metal Box right
	boxes[2] = Box( vec3(uBallPos.x - 5.0, uHalfRoomDimensions.y - 2.0, uBallPos.z - 10.0), vec3(uBallPos.x + 5.0, uHalfRoomDimensions.y - 1.0, uBallPos.z + 10.0), z, vec3(0.955008, 0.637427, 0.538163), SPEC);// Copper Metal Box ceiling
	boxes[3] = Box( vec3(uBallPos.x - 5.0, -uHalfRoomDimensions.y + 1.0, uBallPos.z - 10.0), vec3(uBallPos.x + 5.0, -uHalfRoomDimensions.y + 2.0, uBallPos.z + 10.0), z, vec3(0.955008, 0.637427, 0.538163), SPEC);// Copper Metal Box floor
	boxes[4] = Box( vec3(uPlayerPos.x-uPaddleRadX, uPlayerPos.y-uPaddleRadY, uPlayerPos.z), vec3(uPlayerPos.x+uPaddleRadX, uPlayerPos.y+uPaddleRadY, uPlayerPos.z+3.0), z, vec3(0.1, 0.7, 1.0), uCutSceneIsPlaying ? COAT : REFR);// Player paddle (0.1,0.7,1.0)
	boxes[5] = Box( vec3(uComputerPos.x-uPaddleRadX, uComputerPos.y-uPaddleRadY, uComputerPos.z), vec3(uComputerPos.x+uPaddleRadX, uComputerPos.y+uPaddleRadY, uComputerPos.z+3.0), z, vec3(0.7, 0.1, 1.0), COAT);// Computer A.I. paddle (0.7, 0.1, 1.0)

	quads[0] = Quad( vec3(0,-1, 0), vec3(-lX,lY,-lZ), vec3(lX,lY,-lZ), vec3(lX,lY,lZ), vec3(-lX,lY,lZ), L1, z, LIGHT);// rectangular Area Light in ceiling
}



// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}


void main( void )
{
	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	// the following is not needed - three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
	// calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

	// initialize rand() variables
	counter = -1.0; // will get incremented by 1 on each call to rand()
	channel = 0; // the final selected color channel to use for rand() calc (range: 0 to 3, corresponds to R,G,B, or A)
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	randVec4 = vec4(0); // samples and holds the RGBA blueNoise texture value for this pixel
	randVec4 = texelFetch(tBlueNoiseTexture, ivec2(mod(gl_FragCoord.xy + floor(uRandomVec2 * 256.0), 256.0)), 0);
	
	//vec2 pixelOffset = vec2( tentFilter(rng()), tentFilter(rng()) ) * 0.5;
	vec2 pixelOffset = vec2(0); // achieves 60 FPS even on a smartphone, compared with 50 FPS for above line 
	
	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + pixelOffset) / uResolution) * 2.0 - 1.0;
	
	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	/* // depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rng() * TWO_PI; // pick random point on aperture
	float randomRadius = rng() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos); */
	
	Ray ray = Ray( cameraPosition, rayDir );

	SetupScene();
	
	// Edge Detection - don't want to blur edges where either surface normals change abruptly (i.e. room wall corners), objects overlap each other (i.e. edge of a foreground sphere in front of another sphere right behind it),
	// or an abrupt color variation on the same smooth surface, even if it has similar surface normals (i.e. checkerboard pattern). Want to keep all of these cases as sharp as possible - no blur filter will be applied.
	vec3 objectNormal, objectColor;
	float objectID = -INFINITY;
	float pixelSharpness = 0.0;
	float dynamicSurface = 0.0;
	
	// perform path tracing and get resulting pixel color
	vec4 currentPixel = vec4( vec3(CalculateRadiance(ray, objectNormal, objectColor, objectID, pixelSharpness, dynamicSurface)), 0.0 );

	// if difference between normals of neighboring pixels is less than the first edge0 threshold, the white edge line effect is considered off (0.0)
	float edge0 = 0.2; // edge0 is the minimum difference required between normals of neighboring pixels to start becoming a white edge line
	// any difference between normals of neighboring pixels that is between edge0 and edge1 smoothly ramps up the white edge line brightness (smoothstep 0.0-1.0)
	float edge1 = 0.6; // once the difference between normals of neighboring pixels is >= this edge1 threshold, the white edge line is considered fully bright (1.0)
	float difference_Nx = fwidth(objectNormal.x);
	float difference_Ny = fwidth(objectNormal.y);
	float difference_Nz = fwidth(objectNormal.z);
	float normalDifference = smoothstep(edge0, edge1, difference_Nx) + smoothstep(edge0, edge1, difference_Ny) + smoothstep(edge0, edge1, difference_Nz);

	edge0 = 0.0;
	edge1 = 0.5;
	float difference_obj = abs(dFdx(objectID)) > 0.0 ? 1.0 : 0.0;
	difference_obj += abs(dFdy(objectID)) > 0.0 ? 1.0 : 0.0;
	float objectDifference = smoothstep(edge0, edge1, difference_obj);

	float difference_col = length(dFdx(objectColor)) > 0.0 ? 1.0 : 0.0;
	difference_col += length(dFdy(objectColor)) > 0.0 ? 1.0 : 0.0;
	float colorDifference = smoothstep(edge0, edge1, difference_col);
	// edge detector (normal and object differences) white-line debug visualization
	//currentPixel.rgb += 1.0 * vec3(max(normalDifference, objectDifference));
	
	vec4 previousPixel = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);

	if (dynamicSurface > 0.0 || previousPixel.a == 0.99)
	{
		previousPixel = vec4(0); // motion-blur trail amount (old image)
	}
	else if (uCameraIsMoving) // camera is currently moving
	{
		previousPixel.rgb *= 0.6; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.4; // brightness of new image (noisy)
		
		previousPixel.a = 0.0;
	}
	else 
	{
		previousPixel.rgb *= 0.9; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.1; // brightness of new image (noisy)
	}

	currentPixel.a = 0.0;
	if (colorDifference >= 1.0 || normalDifference >= 1.0 || objectDifference >= 1.0)
		pixelSharpness = 1.01;

	
	// Eventually, all edge-containing pixels' .a (alpha channel) values will converge to 1.01, which keeps them from getting blurred by the box-blur filter, thus retaining sharpness.
	if (previousPixel.a == 1.01)
		currentPixel.a = 1.01;
	// for dynamic scenes
	if (previousPixel.a == 1.01 && rng() < 0.1)
		currentPixel.a = 1.0;

	if (previousPixel.a == -1.0)
		currentPixel.a = 0.0;

	if (pixelSharpness == 1.01)
		currentPixel.a = 1.01;
	if (pixelSharpness == -1.0)
		currentPixel.a = -1.0;
	

	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, dynamicSurface > 0.0 ? 0.99 : currentPixel.a);
}
