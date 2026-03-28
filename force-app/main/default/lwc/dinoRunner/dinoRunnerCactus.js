export default class DinoRunnerCactus {

    constructor(ctx, x, y, width, height, image) {
        this.ctx = ctx;
        this.canvas = ctx.canvas;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.image = image;
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

    update(speed, gameSpeed, timeDelta, scaleRatio) {
        this.x -= speed * gameSpeed * timeDelta * scaleRatio;
    }

    collision(sprite) {
        const adjustBy = 1.4;
        return (sprite.x < this.x + this.width / adjustBy
                && sprite.x + sprite.width / adjustBy > this.x
                && sprite.y < this.y + this.height / adjustBy
                && sprite.height + sprite.y / adjustBy > this.y);
    }

}