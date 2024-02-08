// #[cfg(test)]
// mod tests {
//     use core::option::OptionTrait;
//     use core::traits::TryInto;
//     use starknet::{
//         testing::set_contract_address, class_hash::Felt252TryIntoClassHash, ContractAddress,
//         SyscallResultTrait
//     };
//     use super::{IPostQuantumDispatcher, IPostQuantumDispatcherTrait};
//     use super::IPostQuantum;
//     use super::PostQuantum;

//     fn deploy(calldata: Array<felt252>) -> ContractAddress {
//         let (address, _) = starknet::deploy_syscall(
//             PostQuantum::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
//         )
//             .unwrap_syscall();
//         address
//     }

//     #[test]
//     #[available_gas(2000000000)]
//     fn test_normal_mint() {
//         let admin: ContractAddress = 0x123.try_into().unwrap();
//         let user: ContractAddress = 0x456.try_into().unwrap();
//         set_contract_address(admin);
//         let post_quantum = IPostQuantumDispatcher {
//             contract_address: deploy(array![admin.into()])
//         };
//         post_quantum.open();
//         set_contract_address(user);

//         // mint nft with id 1
//         post_quantum.mint(1);
//     }

//     #[test]
//     #[available_gas(2000000000)]
//     #[should_panic(expected: ('Mint is closed', 'ENTRYPOINT_FAILED'))]
//     fn test_closed_mint() {
//         let admin: ContractAddress = 0x123.try_into().unwrap();
//         let user: ContractAddress = 0x456.try_into().unwrap();
//         let post_quantum = IPostQuantumDispatcher {
//             contract_address: deploy(array![admin.into()])
//         };
//         set_contract_address(user);
//         // mint nft with id 1
//         post_quantum.mint(1);
//     }

//     #[test]
//     #[available_gas(2000000000)]
//     #[should_panic(expected: ('You can only mint once', 'ENTRYPOINT_FAILED'))]
//     fn test_double_mint() {
//         let admin: ContractAddress = 0x123.try_into().unwrap();
//         let user: ContractAddress = 0x456.try_into().unwrap();
//         set_contract_address(admin);
//         let post_quantum = IPostQuantumDispatcher {
//             contract_address: deploy(array![admin.into()])
//         };
//         post_quantum.open();
//         set_contract_address(user);

//         // mint nft with id 1
//         post_quantum.mint(1);
//         // same with 2 (should fail)
//         post_quantum.mint(2);
//     }
// }