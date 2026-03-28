import { LightningElement, track } from 'lwc';
import DinoRunnerScore from "./dinoRunnerScore";
import DinoRunnerPlayer from "./dinoRunnerPlayer";
import DinoRunnerGround from "./dinoRunnerGround";
import DinoRunnerCactusGenerator from "./dinoRunnerCactusGenerator";

const GAME_WIDTH = 800;
const GAME_HEIGHT = 200;

const GAME_DEFAULT_SPEED = 1;
const GAME_SPEED_INCREMENT = 0.000001;
const BACKGROUND_SPEED = 0.5;

const PLAYER_WIDTH = 88 / 1.5; //58
const PLAYER_HEIGHT = 94 / 1.5; //62
const JUMP_MAX_HEIGHT = GAME_HEIGHT;
const JUMP_MIN_HEIGHT = 150;
const GROUND_WIDTH = 2400;
const GROUND_HEIGHT = 24;

let canvas, ctx;
let scaleRatio;

let score = null;
let player = null;
let ground = null;
let obstacleGenerator = null;

let previousTime = null;
let gameOver = false;
let isRunning = false;
let gameSpeed = GAME_DEFAULT_SPEED;

export default class DinoRunner extends LightningElement {

    @track canvasWidth;
    @track canvasHeight;

    renderedCallback() {

        canvas = this.template.querySelector('canvas');
        ctx = canvas.getContext("2d");

        this.renderGame = this.renderGame.bind(this);
        this.setScreen();

        window.addEventListener("keyup", this.resetGame, { once: true });
        window.addEventListener("touchstart", this.resetGame, { once: true });
    }

    setScreen() {

        const screenHeight = Math.min(
            window.innerHeight, 
            document.documentElement.clientHeight
        );

        const screenWidth = Math.min(
            window.innerWidth, 
            document.documentElement.clientWidth
        );

        if (screenWidth / screenHeight < GAME_WIDTH / GAME_HEIGHT) {
            scaleRatio = screenWidth / GAME_WIDTH;
        } else {
            scaleRatio = screenHeight / GAME_HEIGHT;
        }

        if ((GAME_WIDTH * scaleRatio) != this.canvasWidth
        && (GAME_HEIGHT * scaleRatio) != this.canvasHeight) {
            this.canvasWidth = GAME_WIDTH * scaleRatio;
            this.canvasHeight = GAME_HEIGHT * scaleRatio;
        } else {
            this.generateSprites();
        }

    }

    generateSprites() {

        var playerWidth = PLAYER_WIDTH * scaleRatio;
        var playerHeight = PLAYER_HEIGHT * scaleRatio;
        var jumpMinHeight = JUMP_MIN_HEIGHT * scaleRatio;
        var jumpMaxHeight = JUMP_MAX_HEIGHT * scaleRatio;

        player = new DinoRunnerPlayer(
            ctx,
            playerWidth,
            playerHeight,
            jumpMinHeight,
            jumpMaxHeight,
            scaleRatio
        );

        var groundWidth = GROUND_WIDTH * scaleRatio;
        var groundHeight = GROUND_HEIGHT * scaleRatio;

        ground = new DinoRunnerGround(
            ctx, 
            groundWidth, 
            groundHeight, 
            BACKGROUND_SPEED, 
            scaleRatio
        );

        var obstacleWidth = GROUND_WIDTH * scaleRatio;
        var obstacleHeight = GROUND_HEIGHT * scaleRatio;

        obstacleGenerator = new DinoRunnerCactusGenerator(
            ctx, 
            obstacleWidth, 
            obstacleHeight, 
            BACKGROUND_SPEED, 
            scaleRatio
        );

        score = new DinoRunnerScore(ctx, scaleRatio);

        this.renderGame();
    }
    
    resetGame() {

        gameOver = false;
        isRunning = true;
        gameSpeed = GAME_DEFAULT_SPEED;

        score.reset();
        ground.reset();
        obstacleGenerator.reset();

        window.removeEventListener("keyup", this.resetGame, { once: true });
        window.removeEventListener("touchstart", this.resetGame, { once: true });

    }

    renderGame(currentTime) {

        if (previousTime == null) {
            previousTime = currentTime;
            window.requestAnimationFrame(this.renderGame);
            return;
        }

        var timeDelta = currentTime - previousTime;
        previousTime = currentTime;
        
        this.cleanScreen();

        if (!gameOver && isRunning) {
            ground.update(gameSpeed, timeDelta);
            obstacleGenerator.update(gameSpeed, timeDelta);
            player.update(gameSpeed, timeDelta);
            score.update(timeDelta);
            this.updateGameSpeed(timeDelta);
        }

        if (!gameOver && obstacleGenerator.collision(player)) {
            gameOver = true;
            isRunning = false;
            score.saveHighScore();
        }

        ground.draw();
        player.draw();
        score.draw();
        obstacleGenerator.draw();

        if (gameOver) {
            this.showGameOver();
        } else if (!isRunning) {
            this.showStartGame();
        }

        window.requestAnimationFrame(this.renderGame);
    }

    showStartGame() {
        const fontSize = 40 * scaleRatio;
        ctx.font = `${fontSize}px Verdana`;
        ctx.fillStyle = "grey";
        const x = canvas.width / 14;
        const y = canvas.height / 2;
        ctx.fillText("Tap Screen or Press Space To Start", x, y);
    }

    showGameOver() {

        const fontSize = 70 * scaleRatio;
        ctx.font = `${fontSize}px Verdana`;
        ctx.fillStyle = "grey";
        const x = canvas.width / 4.5;
        const y = canvas.height / 2;
        ctx.fillText("GAME OVER", x, y);

        setTimeout(() => {
            window.removeEventListener("keyup", this.resetGame, { once: true });
            window.addEventListener("keyup", this.resetGame, { once: true });
            window.removeEventListener("touchstart", this.resetGame, { once: true });
            window.addEventListener("touchstart", this.resetGame, { once: true });
        }, 1000);
    }

    updateGameSpeed(timeDelta) {
        gameSpeed += timeDelta * GAME_SPEED_INCREMENT;
    }

    cleanScreen() {
        ctx.fillStyle = "white";
        ctx.fillRect(0, 0, canvas.width, canvas.height);
    }

}