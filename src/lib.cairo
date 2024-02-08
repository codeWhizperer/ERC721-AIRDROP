use openzeppelin::{
    token::erc721::{ERC721Component::{ERC721Metadata, HasComponent}},
    introspection::src5::SRC5Component,
};
use custom_uri::{main::custom_uri_component::InternalImpl, main::custom_uri_component};

use starknet::ContractAddress;
#[starknet::interface]
trait IPostQuantum<TState> {
    fn airdrop_token(ref self: TState, addresses: Array<ContractAddress>);
    fn token_uri(self: @TState, tokenId: u256) -> Array<felt252>;
    fn tokenURI(self: @TState, tokenId: u256) -> Array<felt252>;
    fn set_token_uri(ref self: TState, token_uri_base: Span<felt252>);
}

#[starknet::interface]
trait IERC721Metadata<TState> {
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
}

#[starknet::embeddable]
impl IERC721MetadataImpl<
    TContractState,
    +HasComponent<TContractState>,
    +SRC5Component::HasComponent<TContractState>,
    +custom_uri_component::HasComponent<TContractState>,
    +Drop<TContractState>
> of IERC721Metadata<TContractState> {
    fn name(self: @TContractState) -> felt252 {
        let component = HasComponent::get_component(self);
        ERC721Metadata::name(component)
    }

    fn symbol(self: @TContractState) -> felt252 {
        let component = HasComponent::get_component(self);
        ERC721Metadata::symbol(component)
    }
}

#[starknet::contract]
mod SAMPLENFT {
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use core::array::ArrayTrait;
    use core::array::SpanTrait;
    use super::IPostQuantum;
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address, class_hash::ClassHash};
    use custom_uri::{interface::IInternalCustomURI, main::custom_uri_component};
    use openzeppelin::{
        account, access::ownable::OwnableComponent,
        upgrades::{UpgradeableComponent, interface::IUpgradeable},
        token::erc721::{
            ERC721Component, erc721::ERC721Component::InternalTrait as ERC721InternalTrait
        },
        introspection::{src5::SRC5Component, dual_src5::{DualCaseSRC5, DualCaseSRC5Trait}}
    };

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: custom_uri_component, storage: custom_uri, event: CustomUriEvent);

    // allow to check what interface is supported
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5CamelImpl = SRC5Component::SRC5CamelImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    // make it a NFT
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnlyImpl = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    // allow to query name of nft collection
    #[abi(embed_v0)]
    impl IERC721MetadataImpl = super::IERC721MetadataImpl<ContractState>;

    // add an owner
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    // make it upgradable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        opened: bool,
        blacklisted: LegacyMap<ContractAddress, bool>,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        custom_uri: custom_uri_component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        CustomUriEvent: custom_uri_component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
        //change value to preferred NFT_NAME AND NFT_SYMBOL
        self.erc721.initializer('MEME2 NFT', 'MNFT2');
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl PostQuantumImpl of super::IPostQuantum<ContractState> {
        fn airdrop_token(ref self: ContractState, mut addresses: Array<ContractAddress>) {
            self.ownable.assert_only_owner();
            let mut counter = 0;
            let mut tokenId = 0;
            while counter < addresses.len() {
                match addresses.get(counter) {
                    Option::Some(x) => { self.erc721._mint(*x.unbox(), tokenId) },
                    Option::None => ()
                }
                counter += 1;
                tokenId += 1;
            }
        }

        fn tokenURI(self: @ContractState, tokenId: u256) -> Array<felt252> {
            let component = custom_uri_component::HasComponent::get_component(self);
            component.get_base_uri();
            let mut link = component.get_base_uri(); //BaseURI

            // If tokenId is 0, handle it separately
            if tokenId == 0 {
                link.append(0x30); // Append '0' character directly
            } else {
                // Convert int id into Cairo ShortString(bytes) #
                // Reverse number: 12345 -> 54321, 1000 -> 0001
                let mut revNumber: u256 = 0;
                let mut currentInt: u256 = tokenId * 10 + 1;
                loop {
                    revNumber = revNumber * 10 + currentInt % 10;
                    currentInt = currentInt / 10_u256;
                    if currentInt < 1 {
                        break;
                    };
                };

                // Split chart
                loop {
                    let lastChar: u256 = revNumber % 10_u256;
                    link.append(self._intToChar(lastChar)); // BaseURI + TOKEN_ID
                    revNumber = revNumber / 10_u256;
                    if revNumber < 2 { //~ = 1
                        break;
                    };
                };
            }

            link.append(0x2e6a736f6e); // Append .json
            link
        }
        fn token_uri(self: @ContractState, tokenId: u256) -> Array<felt252> {
            self.tokenURI(tokenId)
        }

        fn set_token_uri(ref self: ContractState, token_uri_base: Span<felt252>) {
            self.ownable.assert_only_owner();
            self.custom_uri.set_base_uri(token_uri_base);
        }
    }


    // #################### Base Helper FUNCTION #################### //
    #[generate_trait]
    impl BaseHelperImpl of BaseHelperTrait {
        // convert int short string .  eg: 1 -> 0x31 
        fn _intToChar(self: @ContractState, input: u256) -> felt252 {
            if input == 0 {
                return 0x30;
            } else if input == 1 {
                return 0x31;
            } else if input == 2 {
                return 0x32;
            } else if input == 3 {
                return 0x33;
            } else if input == 4 {
                return 0x34;
            } else if input == 5 {
                return 0x35;
            } else if input == 6 {
                return 0x36;
            } else if input == 7 {
                return 0x37;
            } else if input == 8 {
                return 0x38;
            } else if input == 9 {
                return 0x39;
            }
            0x0
        }
    }
}

