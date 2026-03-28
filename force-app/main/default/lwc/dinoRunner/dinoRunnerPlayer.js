import IMAGES from "@salesforce/resourceUrl/dino_run_assets";
const GRAVITY = 0.4;
const JUMP_SPEED = 0.6;
const RUN_ANIMATION_TIMER = 200;

export default class DinoRunnerPlayer {

    playerRunImages = [];

    falling = false;
    isJumping = false;
    jumpTriggered = false;
    runTimer = RUN_ANIMATION_TIMER;

    constructor(ctx, width, height, jumpMinHeight, jumpMaxHeight, scaleRatio) {

        this.ctx = ctx;
        this.canvas = ctx.canvas;
        this.width = width;
        this.height = height;
        this.jumpMinHeight = jumpMinHeight;
        this.jumpMaxHeight = jumpMaxHeight;
        this.scaleRatio = scaleRatio;

        this.x = 10 * scaleRatio;
        this.y = this.canvas.height - this.height - 1.5 * scaleRatio;
        this.yStandingPosition = this.y;

        this.standingStillImage = new Image();
        this.standingStillImage.src = IMAGES + '/images/dino_standing.png';
        this.image = this.standingStillImage;

        const playerRunImage1 = new Image();
        playerRunImage1.src = IMAGES + '/images/dino_run1.png';
        this.playerRunImages.push(playerRunImage1);

        const playerRunImage2 = new Image();
        playerRunImage2.src = IMAGES + '/images/dino_run2.png';
        this.playerRunImages.push(playerRunImage2);

        window.removeEventListener("keydown", this.keydown);
        window.addEventListener("keydown", this.keydown);
        window.removeEventListener("keyup", this.keyup);
        window.addEventListener("keyup", this.keyup);

        window.removeEventListener("touchstart", this.touchstart);
        window.addEventListener("touchstart", this.touchstart);
        window.removeEventListener("touchend", this.touchend);
        window.addEventListener("touchend", this.touchend);

    }

    draw() {

        this.ctx.drawImage(
            this.image, 
            this.x, 
            this.y, 
            this.width, 
            this.height
        );

    }

    update(gameSpeed, timeDelta) {

        this.run(gameSpeed, timeDelta);

        if (this.isJumping) {
            this.image = this.standingStillImage;
        }

        this.jump(timeDelta);
    }

    run(gameSpeed, timeDelta) {
        if (this.runTimer <= 0) {
            if (this.image == this.playerRunImages[0]) {
                this.image = this.playerRunImages[1];
            } else {
                this.image = this.playerRunImages[0];
            }
            this.runTimer = RUN_ANIMATION_TIMER;
        }
        this.runTimer -= timeDelta * gameSpeed;
    }

    jump(timeDelta) {
        
        if (this.jumpTriggered) {
            this.isJumping = true;
        }

        if (this.isJumping && !this.falling) {

            if (this.y > this.canvas.height - this.jumpMinHeight
                || (this.y > this.canvas.height - this.jumpMaxHeight && this.jumpTriggered)) {
                
                this.y -= JUMP_SPEED * timeDelta * this.scaleRatio;
            } else {
                this.falling = true;
            }

        } else {

            if (this.y < this.yStandingPosition) {
                this.y += GRAVITY * timeDelta * this.scaleRatio;
                if (this.y + this.height > this.canvas.height) {
                    this.y = this.yStandingPosition;
                }
            } else {
                this.falling = false;
                this.isJumping = false;
            }

        }

    }

    touchstart = () => {
        this.jumpTriggered = true;
    };

    touchend = () => {
        this.jumpTriggered = false;
    };

    keydown = (event) => {
        if (event.code === "Space") {
            this.jumpTriggered = true;
        }
    };

    keyup = (event) => {
        if (event.code === "Space") {
            this.jumpTriggered = false;
        }
    };
    
}