import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ownerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

const MyTokenModule = buildModule("MyTokenModule", (m) => {
  const owner = m.getParameter("owner", ownerAddress);

  const myToken = m.contract("MyToken", [owner]);

  return { myToken };
});

export default MyTokenModule;
