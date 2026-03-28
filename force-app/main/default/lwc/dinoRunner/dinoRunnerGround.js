import IMAGES from "@salesforce/resourceUrl/dino_run_assets";

export default class DinoRunnerGround {

    constructor(ctx, width, height, speed, scaleRatio) {

        this.ctx = ctx;
        this.canvas = ctx.canvas;
        this.width = width;
        this.height = height;
        this.speed = speed;
        this.scaleRatio = scaleRatio;

        this.x = 0;
        this.y = this.canvas.height - this.height;

        this.groundAsset = new Image();
        this.groundAsset.src = IMAGES + '/images/ground.png';
        
    }

    draw() {

        this.ctx.drawImage(
            this.groundAsset, 
            this.x, 
            this.y, 
            this.width, 
            this.height
        );

        this.ctx.drawImage(
            this.groundAsset, 
            this.x + this.width, 
            this.y, 
            this.width, 
            this.height
        );

        if (this.x < -this.width) {
            this.x = 0;
        }

    }

    update(gameSpeed, timeDelta) {
        this.x -= gameSpeed * timeDelta * this.speed * this.scaleRatio;
    }

    reset() {
        this.x = 0;
    }

}