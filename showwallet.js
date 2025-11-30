const ethers = require("ethers");
const fs = require("fs");
try {
  const data = fs.readFileSync("F:\\airdrop-hunter\\airdrop\\wallet.txt", "utf8");
  let lines = data.split("\r\n");
  let idx = 1;
  for (let str of lines) {
    if (str.length > 12) {
      try {
        let wallet = ethers.Wallet.fromPhrase(str);

        console.log(idx++, wallet.address);
      } catch (e) {}
    }
  }
} catch (err) {
  console.error("读取文件出错:", err);
}
