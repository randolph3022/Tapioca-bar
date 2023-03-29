/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../../common";
import type {
  ERC1155TokenReceiver,
  ERC1155TokenReceiverInterface,
} from "../../../../../../tapioca-sdk/dist/contracts/YieldBox/contracts/ERC1155TokenReceiver";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "uint256[]",
        name: "",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "",
        type: "uint256[]",
      },
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    name: "onERC1155BatchReceived",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    name: "onERC1155Received",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
] as const;

const _bytecode =
  "0x6080806040523461001657610232908161001c8239f35b600080fdfe608080604052600436101561001357600080fd5b600090813560e01c908163bc197c81146100ad575063f23a6e611461003757600080fd5b346100aa5760a03660031901126100aa57610050610152565b5061005961017a565b5060843567ffffffffffffffff81116100a65761007a9036906004016101ce565b505060206040517ff23a6e61000000000000000000000000000000000000000000000000000000008152f35b5080fd5b80fd5b9050346100a65760a03660031901126100a6576100c8610152565b506100d161017a565b5067ffffffffffffffff916044358381116100a6576100f490369060040161019d565b50506064358381116100a65761010e90369060040161019d565b50506084359283116100aa575061012b60209236906004016101ce565b50507fbc197c81000000000000000000000000000000000000000000000000000000008152f35b6004359073ffffffffffffffffffffffffffffffffffffffff8216820361017557565b600080fd5b6024359073ffffffffffffffffffffffffffffffffffffffff8216820361017557565b9181601f840112156101755782359167ffffffffffffffff8311610175576020808501948460051b01011161017557565b9181601f840112156101755782359167ffffffffffffffff831161017557602083818601950101116101755756fea2646970667358221220f668c24e1eb76b2859a2483cf8892dab0c2c4474f3864af9031754065a54e12464736f6c63430008120033";

type ERC1155TokenReceiverConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: ERC1155TokenReceiverConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class ERC1155TokenReceiver__factory extends ContractFactory {
  constructor(...args: ERC1155TokenReceiverConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ERC1155TokenReceiver> {
    return super.deploy(overrides || {}) as Promise<ERC1155TokenReceiver>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): ERC1155TokenReceiver {
    return super.attach(address) as ERC1155TokenReceiver;
  }
  override connect(signer: Signer): ERC1155TokenReceiver__factory {
    return super.connect(signer) as ERC1155TokenReceiver__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ERC1155TokenReceiverInterface {
    return new utils.Interface(_abi) as ERC1155TokenReceiverInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ERC1155TokenReceiver {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as ERC1155TokenReceiver;
  }
}