import DinoRunnerCactus from "./dinoRunnerCactus";
import IMAGES from "@salesforce/resourceUrl/dino_run_assets";

const OBSTACLE_INTERVAL_MIN = 500;
const OBSTACLE_INTERVAL_MAX = 2000;

const OBSTACLE_MAP = [
    { width: 48 / 1.5, height: 100 / 1.5, image: IMAGES + '/images/cactus_1.png' }, 
    { width: 98 / 1.5, height: 100 / 1.5, image: IMAGES + '/images/cactus_2.png' }, 
    { width: 68 / 1.5, height: 70 / 1.5, image: IMAGES + '/images/cactus_3.png' }, 
];

export default class DinoRunnerCactusGenerator {

    obstacles = [];
    nextObstacleInterval = null;

    constructor(ctx, width, height, speed, scaleRatio) {

        this.ctx = ctx;
        this.canvas = ctx.canvas;
        this.width = width;
        this.height = height;
        this.speed = speed;
        this.scaleRatio = scaleRatio;

        this.obstacleOptions = OBSTACLE_MAP.map((obstacle) => {
            var image = new Image();
            image.src = obstacle.image;
            return {
                image: image, 
                width: obstacle.width * scaleRatio, 
                height: obstacle.height * scaleRatio
            }
        });

        this.setNextObstacle();
    }

    draw() {
        this.obstacles.forEach((obstacle) => obstacle.draw());
    }

    update(gameSpeed, timeDelta) {

        if (this.nextObstacleInterval <= 0) {
            this.createObstacle();
            this.setNextObstacle();
        }

        this.nextObstacleInterval -= timeDelta;

        this.obstacles.forEach((obstacle) => {
            obstacle.update(this.speed, gameSpeed, timeDelta, this.scaleRatio);
        });

        this.obstacles = this.obstacles.filter((obstacle) => obstacle.x > -obstacle.width);
    }

    reset() {
        this.obstacles = [];
    }

    createObstacle() {

        const randomIndex = this.getRandomNumber(0, this.obstacleOptions.length - 1);
        const obstacleImage = this.obstacleOptions[randomIndex];
        const x = this.canvas.width * 1.5;
        const y = this.canvas.height - obstacleImage.height;

        const obstacle = new DinoRunnerCactus(
            this.ctx, 
            x, 
            y, 
            obstacleImage.width, 
            obstacleImage.height, 
            obstacleImage.image
        );

        this.obstacles.push(obstacle);
    }

    setNextObstacle() {

        const randomNum = this.getRandomNumber(
            OBSTACLE_INTERVAL_MIN, 
            OBSTACLE_INTERVAL_MAX
        );

        this.nextObstacleInterval = randomNum;
    }

    collision(sprite) {
        return this.obstacles.some((obstacle) => obstacle.collision(sprite));
    }

    getRandomNumber(min, max) {
        return Math.floor(Math.random() * (max - min + 1) + min);
    }

}