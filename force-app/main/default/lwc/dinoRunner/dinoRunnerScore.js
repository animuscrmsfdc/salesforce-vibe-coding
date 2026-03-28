const HIGH_SCORE_KEY = "highScore";

export default class DinoRunnerScore {

    score = 0;

    constructor(ctx, scaleRatio) {
        this.ctx = ctx;
        this.canvas = ctx.canvas;
        this.scaleRatio = scaleRatio;
    }

    draw() {

        const fontSize = 20 * this.scaleRatio;
        this.ctx.font = `${fontSize}px serif`;
        this.ctx.fillStyle = "#525250";

        const y = 20 * this.scaleRatio;
        const scoreX = this.canvas.width - 75 * this.scaleRatio;
        const highScoreX = scoreX - 135 * this.scaleRatio;

        var highScore = Number(localStorage.getItem(HIGH_SCORE_KEY));
        const scorePadded = Math.floor(this.score).toString().padStart(6, 0);
        const highScorePadded = highScore.toString().padStart(6, 0);

        this.ctx.fillText(scorePadded, scoreX, y);
        this.ctx.fillText(`HIGH ${highScorePadded}`, highScoreX, y);
    }

    update(deltaTime) {
        this.score += deltaTime * 0.01;
    }

    saveHighScore() {

        var highScore = Number(localStorage.getItem(HIGH_SCORE_KEY));
        if (this.score > highScore) {
            localStorage.setItem(HIGH_SCORE_KEY, Math.floor(this.score));
        }

    }

    reset() {
        this.score = 0;
    }

}