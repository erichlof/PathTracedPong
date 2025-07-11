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
#define N_BOXES 7
#define N_QUADS 1


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Box boxes[N_BOXES];
Quad quads[N_QUADS];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_box_interior_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_sample_quad_light>

#include <pathtracing_sample_sphere_light>



//---------------------
float SceneIntersect( )
//---------------------
{
	vec3 n;
	float d = INFINITY;
	float t = INFINITY;
	int objectCount = 0;
	int isRayExiting = FALSE;
	
	
	d = SphereIntersect( spheres[0].radius, spheres[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[0].position;
		hitEmission = spheres[0].emission;
		hitColor = spheres[0].color;
		hitType = spheres[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, FALSE);
	if (d < t)
	{
		t = d;
		hitNormal = quads[0].normal;
		hitEmission = quads[0].emission;
		hitColor = quads[0].color;
		hitType = quads[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxInteriorIntersect( boxes[6].minCorner, boxes[6].maxCorner, rayOrigin, rayDirection, n );
	if (d < t && n != vec3(0,0,-1))
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[6].emission;
	
		if (n == vec3(0,0,1)) // back mirror wall
		{
			hitColor = vec3(0.1);
			hitType = SPEC;
		}
		else if (n == vec3(0,-1,0)) // ceiling
		{
			hitColor = vec3(0.1);
			hitType = DIFF;
		}
		else if (n == vec3(0,1,0)) // floor
		{
			hitColor = vec3(0.9);
			hitType = COAT;
		}
		else if (n == vec3(1,0,0)) // left red wall
		{
			hitColor = vec3(1, 0, 0);
			hitType = COAT;
		}
		else //if (n == vec3(-1,0,0)) // right green wall
		{
			hitColor = vec3(0, 0.7, 0);
			hitType = COAT;
		}
		
		hitObjectID = float(objectCount);
	}
	objectCount++;


	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		//finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[1].emission;
		hitColor = boxes[1].color;
		hitType = boxes[1].type;
		//finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[2].minCorner, boxes[2].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[2].emission;
		hitColor = boxes[2].color;
		hitType = boxes[2].type;
		//finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[3].minCorner, boxes[3].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[3].emission;
		hitColor = boxes[3].color;
		hitType = boxes[3].type;
		//finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[4].minCorner, boxes[4].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[4].emission;
		hitColor = boxes[4].color;
		hitType = boxes[4].type;
		//finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[5].minCorner, boxes[5].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[5].emission;
		hitColor = boxes[5].color;
		hitType = boxes[5].type;
		//finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	return t;
} // end float SceneIntersect( )


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness, out float dynamicSurface )
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float previousObjectID;

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int lastHitWasSpec = FALSE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;

	dynamicSurface = 0.0;

	
	for (int bounces = 0; bounces < 10; bounces++)
	{
		// if (isReflectionTime == TRUE)
		// 	reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect();
		
		
		if (t == INFINITY)
		{
			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 1;
				continue;
			}

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				isDiffuseBounceTime = FALSE;
				diffuseCount = 0;
				continue;
			}

			break;
		}

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		
		if (bounces == 0)
		{
			objectID = hitObjectID;
		}
		if (isReflectionTime == FALSE && diffuseCount == 0 && hitObjectID != previousObjectID)
		{
			objectNormal += n;
			objectColor += hitColor;
		}
		
		
		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0 && hitEmission == vec3(10))
				dynamicSurface = 1.0;		
			
			if (diffuseCount == 0 && isReflectionTime == FALSE)
				pixelSharpness = 1.0;

			if (isReflectionTime == TRUE && bounceIsSpecular == TRUE)
			{
				objectNormal += nl;
				//objectColor = hitColor;
				objectID += hitObjectID;
			}

			if (sampleLight == TRUE)
				accumCol += mask * hitEmission;
			else if (bounceIsSpecular == TRUE)
			{
				accumCol += mask * clamp(hitEmission, 0.0, 1.0);
			}
				
			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 1;
				continue;
			}

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				isDiffuseBounceTime = FALSE;
				diffuseCount = 0;
				continue;
			}
			// reached a light, so we can exit
			break;
		}


		
			
		

		// make player's background mirror reflection a solid plastic surface 
		if (lastHitWasSpec == TRUE && hitType == REFR)
			hitType = COAT;

		 
                if (hitType == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = FALSE;

			rayOrigin = x + nl * uEPS_intersect;
                        
			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}
                        
			// if (diffuseCount == 1)
			// {
			// 	rayDirection = sampleSphereLight(x, nl, spheres[0], weight);
			// 	mask *= 2.0;
			// }	
			// else
			// 	rayDirection = sampleQuadLight(x, nl, quads[0], weight);	
			if (distance(x, uBallPos) < rng() * 100.0 && rng() < dot(nl, normalize(uBallPos - x)))
				rayDirection = sampleSphereLight(x, nl, spheres[0], weight);
			else
				rayDirection = sampleQuadLight(x, nl, quads[0], weight);
				
			mask *= weight;
			sampleLight = TRUE;
			continue;
                        
		} // end if (hitType == DIFF)
		
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			lastHitWasSpec = TRUE;

			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			continue;
		}

		

		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			// transmit ray through surface
			mask *= hitColor;
			mask *= Tr;
			
			//rayDirection = refract(rayDirection, nl, ratioIoR);
			rayDirection = rayDirection;
			rayOrigin = x - nl * uEPS_intersect;

			// if (diffuseCount == 1)
			// 	bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)

		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (hitColor == vec3(0.7, 0.1, 1.0) && (bounces == 0 || previousIntersecType == REFR))
			{
				dynamicSurface = 1.0;
			}
			
			if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;
			
			mask *= Tr;
			mask *= hitColor;
			
			bounceIsSpecular = FALSE;
			
			rayOrigin = x + nl * uEPS_intersect;
                        
			// if (diffuseCount == 1)
			// {
			// 	diffuseBounceMask = mask;
			// 	diffuseBounceRayOrigin = rayOrigin;
			// 	diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
			// 	willNeedDiffuseBounceRay = TRUE;
			// }

			if (distance(x, uBallPos) < rng() * 100.0 && rand() < dot(nl, normalize(uBallPos - x)))
				rayDirection = sampleSphereLight(x, nl, spheres[0], weight);
			else
				rayDirection = sampleQuadLight(x, nl, quads[0], weight);

			mask *= weight;
			sampleLight = TRUE;
			continue;
			
		} //end if (hitType == COAT)
		

	} // end for (int bounces = 0; bounces < 10; bounces++)
	
	
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
	
	boxes[0] = Box( vec3(-uHalfRoomDimensions.x + 1.0, uBallPos.y - 5.0, uBallPos.z - 10.0), vec3(-uHalfRoomDimensions.x + 2.0, uBallPos.y + 5.0, uBallPos.z + 10.0), z, vec3(1.0, 0.765557, 0.336057), SPEC);// Gold Metal Box left
	boxes[1] = Box( vec3( uHalfRoomDimensions.x - 2.0, uBallPos.y - 5.0, uBallPos.z - 10.0), vec3( uHalfRoomDimensions.x - 1.0, uBallPos.y + 5.0, uBallPos.z + 10.0), z, vec3(1.0), SPEC);// Aluminum Metal Box right
	boxes[2] = Box( vec3(uBallPos.x - 5.0, uHalfRoomDimensions.y - 2.0, uBallPos.z - 10.0), vec3(uBallPos.x + 5.0, uHalfRoomDimensions.y - 1.0, uBallPos.z + 10.0), z, vec3(0.955008, 0.637427, 0.538163), SPEC);// Copper Metal Box ceiling
	boxes[3] = Box( vec3(uBallPos.x - 5.0, -uHalfRoomDimensions.y + 1.0, uBallPos.z - 10.0), vec3(uBallPos.x + 5.0, -uHalfRoomDimensions.y + 2.0, uBallPos.z + 10.0), z, vec3(0.955008, 0.637427, 0.538163), SPEC);// Copper Metal Box floor
	boxes[4] = Box( vec3(uPlayerPos.x-uPaddleRadX, uPlayerPos.y-uPaddleRadY, uPlayerPos.z), vec3(uPlayerPos.x+uPaddleRadX, uPlayerPos.y+uPaddleRadY, uPlayerPos.z+3.0), z, vec3(0.1, 0.7, 1.0), uCutSceneIsPlaying ? COAT : REFR);// Player paddle (0.1,0.7,1.0)
	boxes[5] = Box( vec3(uComputerPos.x-uPaddleRadX, uComputerPos.y-uPaddleRadY, uComputerPos.z), vec3(uComputerPos.x+uPaddleRadX, uComputerPos.y+uPaddleRadY, uComputerPos.z+3.0), z, vec3(0.7, 0.1, 1.0), COAT);// Computer A.I. paddle (0.7, 0.1, 1.0)
	boxes[6] = Box( -uHalfRoomDimensions, uHalfRoomDimensions, z, vec3(1), COAT);

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
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	blueNoise = texelFetch(tBlueNoiseTexture, ivec2(mod(floor(gl_FragCoord.xy), 128.0)), 0).r;

	vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) );
	//pixelOffset *= 0.5;//uCameraIsMoving ? 0.5 : 1.0;

	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + vec2(0.5) + pixelOffset) / uResolution) * 2.0 - 1.0;
	
	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	/* // depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rng() * TWO_PI; // pick random point on aperture
	float randomRadius = rng() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos); */
	
	rayOrigin = cameraPosition;
	rayDirection = rayDir;

	SetupScene();
	
	// Edge Detection - don't want to blur edges where either surface normals change abruptly (i.e. room wall corners), objects overlap each other (i.e. edge of a foreground sphere in front of another sphere right behind it),
	// or an abrupt color variation on the same smooth surface, even if it has similar surface normals (i.e. checkerboard pattern). Want to keep all of these cases as sharp as possible - no blur filter will be applied.
	vec3 objectNormal, objectColor;
	float objectID = -INFINITY;
	float pixelSharpness = 0.0;
	float dynamicSurface = 0.0;
	
	// perform path tracing and get resulting pixel color
	vec4 currentPixel = vec4( vec3(CalculateRadiance(objectNormal, objectColor, objectID, pixelSharpness, dynamicSurface)), 0.0 );

	// if difference between normals of neighboring pixels is less than the first edge0 threshold, the white edge line effect is considered off (0.0)
	float edge0 = 0.2; // edge0 is the minimum difference required between normals of neighboring pixels to start becoming a white edge line
	// any difference between normals of neighboring pixels that is between edge0 and edge1 smoothly ramps up the white edge line brightness (smoothstep 0.0-1.0)
	float edge1 = 0.6; // once the difference between normals of neighboring pixels is >= this edge1 threshold, the white edge line is considered fully bright (1.0)
	float difference_Nx = fwidth(objectNormal.x);
	float difference_Ny = fwidth(objectNormal.y);
	float difference_Nz = fwidth(objectNormal.z);
	float normalDifference = smoothstep(edge0, edge1, difference_Nx) + smoothstep(edge0, edge1, difference_Ny) + smoothstep(edge0, edge1, difference_Nz);

	float objectDifference = min(fwidth(objectID), 1.0);

	float colorDifference = (fwidth(objectColor.r) + fwidth(objectColor.g) + fwidth(objectColor.b)) > 0.0 ? 1.0 : 0.0;
	// white-line debug visualization for normal difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(normalDifference);
	// white-line debug visualization for object difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(objectDifference);
	// white-line debug visualization for color difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(colorDifference);
	// white-line debug visualization for all 3 differences
	//currentPixel.rgb += (rng() * 1.5) * vec3( clamp(max(normalDifference, max(objectDifference, colorDifference)), 0.0, 1.0) );
	
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

	currentPixel.a = pixelSharpness;

	// check for all edges that are not light sources
	if (pixelSharpness < 1.01 && (colorDifference >= 1.0 || normalDifference >= 0.9 || objectDifference >= 1.0)) // all other edges
		currentPixel.a = pixelSharpness = 1.0;

	// makes light source edges (shape boundaries) more stable
	// if (previousPixel.a == 1.01)
	// 	currentPixel.a = 1.01;

	// makes sharp edges more stable
	if (previousPixel.a == 1.0)
		currentPixel.a = 1.0;
		
	// for dynamic scenes (to clear out old, dark, sharp pixel trails left behind from moving objects)
	if (previousPixel.a == 1.0 && rng() < 0.05)
		currentPixel.a = 0.0;
	

	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, dynamicSurface > 0.0 ? 0.99 : currentPixel.a);
}
