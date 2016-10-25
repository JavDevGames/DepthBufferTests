package  
{
	import flare.basic.Scene3D;
	import flare.basic.Viewer3D;
	import flare.core.Pivot3D;
	import flare.core.Texture3D;
	import flare.flsl.FLSL;
	import flare.flsl.FLSLMaterial;
	import flare.materials.filters.ColorFilter;
	import flare.materials.filters.TextureMapFilter;
	import flare.materials.Material3D;
	import flare.materials.Shader3D;
	import flare.primitives.Cube;
	import flare.primitives.Plane;
	import flare.primitives.Sphere;
	import flare.system.Device3D;
	import flare.system.Input3D;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DTriangleFace;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	public class DepthBufferTests extends Sprite 
	{
		[Embed(source = "../bin/vaca.zf3d", mimeType = "application/octet-stream")]
		private var model:Class;
		[Embed(source = "../bin/mrt.flsl.compiled", mimeType = "application/octet-stream")]
		private var flsl:Class;
		
		[Embed(source="../bin/depth_glow_test.flsl.compiled", mimeType="application/octet-stream")]
		private var depthGlowFLSL:Class;
		
		[Embed(source = "../bin/depth.png")]
		private var defaultTexture:Class;
		
		[Embed(source = "../bin/front_back.png")]
		private var frontBackTexture:Class;
		
		[Embed(source = "../bin/floorTexture.png")]
		private var floorAsset:Class;
		
		private var scene:Scene3D;
		private var texture0:Texture3D;
		private var texture1:Texture3D;
		private var texture2:Texture3D;
		private var texture3:Texture3D;
		private var mrt:FLSLMaterial;
		private var mDepthMaterial:FLSLMaterial;
		
		private var mTestMaterial:Shader3D;
		
		private var mSphere:Pivot3D;
		private var startModel:Pivot3D;
		private var mRenderMat:Shader3D;
		
		private var mFloor:Plane;
		private var mFloorMaterial:Shader3D;
		
		public function DepthBufferTests() 
		{
			FLSL.agalVersion = 2;
			Device3D.profile = "standard";
			
			scene = new Viewer3D( stage, null, 0.4 );
			scene.skipFrames = false;
			scene.autoResize = true;
			scene.antialias = 2;
			scene.showLogo = false;
			
			var size:int = 1024;
			var bmp:BitmapData = new BitmapData(size, size);
			
			var format:int = Texture3D.FORMAT_RGBA;
			texture0 = new Texture3D( bmp, true, format );
			setupTexture(texture0);
			
			texture0.upload( scene );
			
			texture1 = new Texture3D( bmp, true, format );
			setupTexture(texture1);
			texture1.upload( scene );
			
			texture2 = new Texture3D( bmp, true, format );
			setupTexture(texture2);
			texture2.upload( scene );
			
			texture3 = new Texture3D( bmp, true, format );
			setupTexture(texture3);
			texture3.upload( scene );
			
			// external loading.
			scene.addChildFromFile( new model);
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			//scene.clearColor.setTo(0, 0, 0);
			
			mRenderMat = new Shader3D("", [new ColorFilter(0x990000)]);
		}
		
		private function setupTexture(tex:Texture3D):void 
		{
			tex.typeMode = Texture3D.TYPE_2D;
			//tex.mipMode = Texture3D.MIP_NONE;
			//tex.bias = 0;
		}
		
		private function renderEvent(e:Event):void 
		{
			e.preventDefault();
			
			if ( !scene.context ) return;
			
			scene.setMaterial( mrt );
			
			// this updates the input, animations and object states.
			scene.update();
			
			
			scene.context.setRenderToTexture( texture0.texture, true, 0, 0, 0 );
			scene.context.setRenderToTexture( texture1.texture, true, 0, 0, 1 );
			scene.context.setRenderToTexture( texture2.texture, true, 0, 0, 2 );
			scene.context.setRenderToTexture( texture3.texture, true, 0, 0, 3 );
			scene.context.clear();
			
			mrt.setTechnique( "main" );
			
			// setup seom global matrices and constants configurations.
			scene.setupFrame( scene.camera );
			// go trough each object to draw one by one.
			for each ( var p:Pivot3D in scene.renderList )
			{
				if (p is Cube)
				{
					p.draw(false);
				}
				else if (p is Plane)
				{
					p.draw(false);
				}
			}
			// release GPU states.
			scene.endFrame();
			
			scene.context.setRenderToTexture( null, false, 0, 0, 1 );
			scene.context.setRenderToTexture( null, false, 0, 0, 2 );
			scene.context.setRenderToTexture( null, false, 0, 0, 3 );
			scene.context.setRenderToBackBuffer();
			
			//draw them twice, fix this soon
			for each ( var postElements:Pivot3D in scene.renderList )
			{
				if (postElements ==  mSphere)
				{
					mDepthMaterial.params.depthTexture.mip = 0;
					mDepthMaterial.blendMode = Material3D.BLEND_ADDITIVE;
					postElements.draw(false, mDepthMaterial);
				}
				else if(postElements is Cube)
				{
					postElements.draw(false, mRenderMat);
				}
				else if (postElements is Plane)
				{
					postElements.draw(false, mFloorMaterial);
				}
			}
			
			//debug the "depth" texture on-screen
			var texWidth:int = 320;
			scene.drawQuadTexture( texture1, stage.stageWidth-texWidth, 0, texWidth, 240 );
		}
		
		private function completeEvent(e:Event):void 
		{
			var i:int;
			
			scene.context.enableErrorChecking = true;
			scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
			scene.addEventListener(Scene3D.UPDATE_EVENT, onUpdate);
			
			mrt = new FLSLMaterial( "", new flsl, null, true );
			mrt.params.cube.value = new Texture3D( "skybox2b.png", false, Texture3D.FORMAT_RGBA, Texture3D.TYPE_CUBE );
			
			while (scene.children.length)
			{
				scene.removeChild(scene.children[0]); 
			}
			
			mDepthMaterial = new FLSLMaterial("", new depthGlowFLSL, "main", true);			
			mDepthMaterial.params.depthTexture.value = texture1; 
			
			mDepthMaterial.blendMode = Material3D.BLEND_ADDITIVE;
			
			//var fbTex:Texture3D = new Texture3D(new frontBackTexture);			
			//mTestMaterial = new Shader3D("", [new TextureMapFilter(fbTex, 0, BlendMode.ADD)]);
			//mTestMaterial.blendMode = Material3D.BLEND_ADDITIVE;
			//mTestMaterial.cullFace = Context3DTriangleFace.NONE;
			
			mSphere = new Sphere("", 40, 24, mDepthMaterial);
			
			scene.addChild(mSphere);
			
			var curCube:Cube;
			
			for (i = 0; i < 15; ++i)
			{
				curCube = new Cube("", 10, 10, 10, 1, mRenderMat);
				curCube.setPosition((i % 5) * 20, 10  + 10 * (int(i/5)), (int(i / 5) * 20));
				scene.addChild(curCube);
			}
			
			var floorTexture:Texture3D = new Texture3D(new floorAsset);
			mFloorMaterial = new Shader3D("", [new TextureMapFilter(floorTexture)]);
			mFloor = new Plane("", 1000, 1000, 10, mFloorMaterial, "+xz");
			scene.addChild(mFloor);
		}
		
		private static var POSITION_HELPER:Vector3D = new Vector3D();
		private function onUpdate(e:Event):void 
		{
			const speed:Number = 0.4;
			if (Input3D.keyDown(Input3D.W))
			{
				POSITION_HELPER.x += scene.camera.getDir().x;
				POSITION_HELPER.z += scene.camera.getDir().z;
			}
			else if (Input3D.keyDown(Input3D.S))
			{
				POSITION_HELPER.x -= scene.camera.getDir().x;
				POSITION_HELPER.z -= scene.camera.getDir().z;
			}
			
			if (Input3D.keyDown(Input3D.A))
			{
				POSITION_HELPER.x += scene.camera.getLeft().x;
				POSITION_HELPER.z += scene.camera.getLeft().z;
			}
			else if (Input3D.keyDown(Input3D.D))
			{
				POSITION_HELPER.x -= scene.camera.getLeft().x;
				POSITION_HELPER.z -= scene.camera.getLeft().z;
			}
			
			if (Input3D.keyDown(Input3D.DOWN))
			{
				POSITION_HELPER.y -= speed;
			}
			else if (Input3D.keyDown(Input3D.UP))
			{
				POSITION_HELPER.y += speed;
			}
			
			mSphere.setPosition(POSITION_HELPER.x, POSITION_HELPER.y, POSITION_HELPER.z);
		}
	}
}