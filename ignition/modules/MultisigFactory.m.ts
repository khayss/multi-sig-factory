import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MultisigFactoryModule = buildModule("MultisigFactoryModule", (m) => {
  const multisigFactory = m.contract("MultisigFactory", [], {});

  return { multisigFactory };
});

export default MultisigFactoryModule;
