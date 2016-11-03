package  
{
	import com.GameScene;
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
	import flash.utils.getTimer;
	
	public class DepthBufferTests extends Sprite 
	{
		[Embed(source = "../bin/vaca.zf3d", mimeType = "application/octet-stream")]
		private var model:Class;
		
		[Embed(source = "../bin/mrt.flsl.compiled", mimeType = "application/octet-stream")]
		private var flsl:Class;
		
		[Embed(source="../bin/depth_glow_test.flsl.compiled", mimeType="application/octet-stream")]
		private var depthGlowFLSL:Class;
		
		[Embed(source="../bin/floorTexture.png")]
		private var floorAsset:Class;
		
		private static var POSITION_HELPER:Vector3D = new Vector3D();
		
		private var mScene:Scene3D;
		private var mColorBuffer:Texture3D;
		private var mDepthTexture:Texture3D;
		private var mMRT:FLSLMaterial;
		
		private var mDepthMaterial:FLSLMaterial;
		
		private var mSphere:Pivot3D;
		private var startModel:Pivot3D;
		private var mRenderMaterial:Shader3D;
		private var mFloorMaterial:Shader3D;
		private var mGameScene:GameScene;
		
		private var mLastTime:Number;
		
		public function DepthBufferTests() 
		{
			FLSL.agalVersion = 2;
			Device3D.profile = "standard";
			
			//setup the scene
			mScene = new Viewer3D( stage, null, 0.4 );
			mScene.skipFrames = false;
			mScene.autoResize = true;
			mScene.antialias = 2;
			mScene.showLogo = false;
			
			SetupTextures();
			SetupMaterials();
			
			// external loading.
			mScene.addChildFromFile( new model);
			mScene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			mScene.clearColor.setTo(0, 0, 0);
			
			mLastTime = getTimer();
		}
		
		private function SetupTextures():void
		{
			var size:int = 1024;
			var bmp:BitmapData = new BitmapData(size, size);
			
			var format:int = Texture3D.FORMAT_RGBA_HALF_FLOAT;
			
			mColorBuffer = new Texture3D( bmp, true, format );
			SetupTexture(mColorBuffer);			
			mColorBuffer.upload( mScene );
			
			mDepthTexture = new Texture3D( bmp, true, format );
			SetupTexture(mDepthTexture);
			mDepthTexture.upload( mScene );
		}
		
		private function SetupMaterials():void
		{
			mRenderMaterial = new Shader3D("", [new ColorFilter(0x990000)]);
			
			var floorTexture:Texture3D = new Texture3D(new floorAsset);
			mFloorMaterial = new Shader3D("", [new TextureMapFilter(floorTexture)]);
			
			mDepthMaterial = new FLSLMaterial("", new depthGlowFLSL, "main", true);			
			mDepthMaterial.params.depthTexture.value = mDepthTexture;			
			mDepthMaterial.blendMode = Material3D.BLEND_ADDITIVE;
		}
		
		private function SetupTexture(tex:Texture3D):void 
		{
			tex.typeMode = Texture3D.TYPE_2D;
		}
		
		private function renderEvent(e:Event):void 
		{
			e.preventDefault();
			
			if ( !mScene.context )
			{
				return;
			}
			
			mScene.setMaterial( mMRT );
			
			// this updates the input, animations and object states.
			mScene.update();
			
			mScene.context.setRenderToTexture( mColorBuffer.texture, true, 0, 0, 0 );
			mScene.context.setRenderToTexture( mDepthTexture.texture, true, 0, 0, 1 );
			mScene.context.clear();
			
			mMRT.setTechnique("main");
			
			// setup seom global matrices and constants configurations.
			mScene.setupFrame( mScene.camera );
			
			// go trough each object to draw one by one.
			for each ( var p:Pivot3D in mScene.renderList )
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
			mScene.endFrame();
			
			mScene.context.setRenderToTexture( null, false, 0, 0, 1 );
			mScene.context.setRenderToBackBuffer();
			
			//draw them twice, fix this soon
			for each ( var postElements:Pivot3D in mScene.renderList )
			{
				if (postElements ==  mSphere)
				{
					postElements.draw(false, mDepthMaterial);
				}
				else if(postElements is Cube)
				{
					postElements.draw(false, mRenderMaterial);
				}
				else if (postElements is Plane)
				{
					postElements.draw(false, mFloorMaterial);
				}
			}
			
			//debug the "depth" texture on-screen
			var texWidth:int = 320;
			mScene.drawQuadTexture( mDepthTexture, stage.stageWidth-texWidth, 0, texWidth, 240 );
		}
		
		private function completeEvent(e:Event):void 
		{
			mScene.context.enableErrorChecking = true;
			mScene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
			mScene.addEventListener(Scene3D.UPDATE_EVENT, onUpdate);
			
			mMRT = new FLSLMaterial( "", new flsl, null, true );
			
			while (mScene.children.length)
			{
				mScene.removeChild(mScene.children[0]); 
			}
			
			
			//setup the depth material
			AddEffectsMesh();
			
			mGameScene = new GameScene(mScene, mFloorMaterial, mRenderMaterial);
		}		
		
		private function AddEffectsMesh():void
		{
			mSphere = new Sphere("", 40, 24, mDepthMaterial);			
			mScene.addChild(mSphere);
		}		
		
		private function onUpdate(e:Event):void 
		{
			var curTime:Number = getTimer();
			var diff:Number = curTime - mLastTime;
			
			//for moving the sphere around, based on the camera's direction
			const speed:Number = 0.8 * (diff / 16);
			
			
			if (Input3D.keyDown(Input3D.W))
			{
				POSITION_HELPER.x += mScene.camera.getDir().x;
				POSITION_HELPER.z += mScene.camera.getDir().z;
			}
			else if (Input3D.keyDown(Input3D.S))
			{
				POSITION_HELPER.x -= mScene.camera.getDir().x;
				POSITION_HELPER.z -= mScene.camera.getDir().z;
			}
			
			if (Input3D.keyDown(Input3D.A))
			{
				POSITION_HELPER.x += mScene.camera.getLeft().x;
				POSITION_HELPER.z += mScene.camera.getLeft().z;
			}
			else if (Input3D.keyDown(Input3D.D))
			{
				POSITION_HELPER.x -= mScene.camera.getLeft().x;
				POSITION_HELPER.z -= mScene.camera.getLeft().z;
			}
			
			if (Input3D.keyDown(Input3D.DOWN))
			{
				POSITION_HELPER.y -= speed;
			}
			else if (Input3D.keyDown(Input3D.UP))
			{
				POSITION_HELPER.y += speed;
			}
			
			//update the final position
			mSphere.setPosition(POSITION_HELPER.x, POSITION_HELPER.y, POSITION_HELPER.z);
			
			mLastTime = curTime;
		}
	}
}