import { useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi';
import { parseUnits, Address } from 'viem';
import { BATCH_TRANSFER_CONTRACT, TOKEN_ADDRESSES } from '@/lib/contracts/batchTransfer';

export type BatchTransferRecipient = {
  address: Address;
  amount: string;
};

/**
 * Hook for batch transferring CELO or ERC20 tokens
 */
export function useBatchTransfer() {
  const { data: hash, writeContract, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  /**
   * Execute batch transfer
   * @param tokenAddress - Token contract address (use TOKEN_ADDRESSES.CELO for native CELO)
   * @param recipients - Array of recipients with address and amount
   * @param decimals - Token decimals (18 for CELO, cUSD, etc.)
   */
  const executeBatchTransfer = async (
    tokenAddress: Address,
    recipients: BatchTransferRecipient[],
    decimals: number = 18
  ) => {
    const addresses = recipients.map((r) => r.address);
    const amounts = recipients.map((r) => parseUnits(r.amount, decimals));

    // Calculate total amount for native CELO transfers
    const totalAmount = amounts.reduce((sum, amount) => sum + amount, 0n);

    const isNativeCELO = tokenAddress === TOKEN_ADDRESSES.CELO;

    writeContract({
      address: BATCH_TRANSFER_CONTRACT.address,
      abi: BATCH_TRANSFER_CONTRACT.abi,
      functionName: 'batchTransfer',
      args: [tokenAddress, addresses, amounts],
      value: isNativeCELO ? totalAmount : 0n,
    });
  };

  return {
    executeBatchTransfer,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

/**
 * Hook to check if contract is paused
 */
export function useContractPaused() {
  const { data: isPaused, isLoading } = useReadContract({
    address: BATCH_TRANSFER_CONTRACT.address,
    abi: BATCH_TRANSFER_CONTRACT.abi,
    functionName: 'paused',
  });

  return { isPaused: isPaused ?? false, isLoading };
}
