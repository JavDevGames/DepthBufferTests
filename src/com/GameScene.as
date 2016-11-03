package com
{
	import flare.basic.Scene3D;
	import flare.core.Pivot3D;
	import flare.core.Texture3D;
	import flare.materials.filters.TextureMapFilter;
	import flare.materials.Material3D;
	import flare.materials.Shader3D;
	import flare.primitives.Cube;
	import flare.primitives.Plane;
	/**
	 * ...
	 * @author Javier
	 */
	public class GameScene 
	{
		public static const MAX_CUBES:int = 15;
		public static const PLANE_DIMS:int = 1000;
		
		private var mFloor:Plane;
		private var mFloorMaterial:Shader3D;
		private var mRenderMaterial:Shader3D;
		private var mWalls:Vector.<Pivot3D>;
		private var mScene:Scene3D;
		
		public function GameScene(scene:Scene3D, floorMat:Shader3D, renderMat:Shader3D) 
		{
			mScene = scene;
			mFloorMaterial = floorMat;
			mRenderMaterial = renderMat;
			
			Init();
		}
		
		private function Init():void
		{
			var i:int;
			var curCube:Cube;
			
			var posX:Number;
			var posY:Number;
			var posZ:Number;
			
			for (i = 0; i < MAX_CUBES; ++i)
			{
				posX = (i % 5) * 20;
				posY = 10  + 10 * (int(i / 5));
				posZ = (int(i / 5) * 20);
				
				curCube = new Cube("", 10, 10, 10, 1, mRenderMaterial);
				curCube.setPosition(posX, posY, posZ);
				
				mScene.addChild(curCube);
			}
			
			mFloor = new Plane("", PLANE_DIMS, PLANE_DIMS, 10, mFloorMaterial, "+xz");
			mScene.addChild(mFloor);
			
			AddWalls();
		}
		
		private function AddWalls():void 
		{
			mWalls = new Vector.<Pivot3D>();
			
			mWalls[0] = new Plane("", PLANE_DIMS, PLANE_DIMS, 10, mFloorMaterial, "+xy");
			mWalls[0].z = PLANE_DIMS/2;
			
			
			mWalls[1] = new Plane("", PLANE_DIMS, PLANE_DIMS, 10, mFloorMaterial, "+xy");
			mWalls[1].z = -PLANE_DIMS/2;
			mWalls[1].rotateY(180);
			
			
			mWalls[2] = new Plane("", PLANE_DIMS, PLANE_DIMS, 10, mFloorMaterial, "+xy");
			mWalls[2].x = -PLANE_DIMS/2;
			mWalls[2].rotateY(-90);
			
			
			mWalls[3] = new Plane("", PLANE_DIMS, PLANE_DIMS, 10, mFloorMaterial, "+xy");
			mWalls[3].x = PLANE_DIMS/2;
			mWalls[3].rotateY(90);
			
			
			mWalls[4] = new Plane("", PLANE_DIMS, PLANE_DIMS, 10, mFloorMaterial, "+xz");
			mWalls[4].y = PLANE_DIMS/2;
			mWalls[4].rotateZ(180);
			
			
			//add the walls
			mScene.addChild(mWalls[0]);
			mScene.addChild(mWalls[1]);
			mScene.addChild(mWalls[2]);
			mScene.addChild(mWalls[3]);
			mScene.addChild(mWalls[4]);
		}
	}

}