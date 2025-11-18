import { useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi';
import { Address, parseUnits, erc20Abi } from 'viem';
import { BATCH_TRANSFER_CONTRACT } from '@/lib/contracts/batchTransfer';

/**
 * Hook for approving ERC20 tokens for batch transfer
 */
export function useTokenApproval(tokenAddress: Address) {
  const { data: hash, writeContract, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  /**
   * Approve tokens for batch transfer
   * @param amount - Amount to approve (in token units, e.g., "100.5")
   * @param decimals - Token decimals (default 18)
   */
  const approve = (amount: string, decimals: number = 18) => {
    const parsedAmount = parseUnits(amount, decimals);

    writeContract({
      address: tokenAddress,
      abi: erc20Abi,
      functionName: 'approve',
      args: [BATCH_TRANSFER_CONTRACT.address, parsedAmount],
    });
  };

  return {
    approve,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

/**
 * Hook to check current allowance
 */
export function useTokenAllowance(tokenAddress: Address, ownerAddress?: Address) {
  const { data: allowance, isLoading, refetch } = useReadContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: 'allowance',
    args: ownerAddress ? [ownerAddress, BATCH_TRANSFER_CONTRACT.address] : undefined,
    query: {
      enabled: !!ownerAddress,
    },
  });

  return { allowance: allowance ?? 0n, isLoading, refetch };
}

/**
 * Hook to get token balance
 */
export function useTokenBalance(tokenAddress: Address, ownerAddress?: Address) {
  const { data: balance, isLoading, refetch } = useReadContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: 'balanceOf',
    args: ownerAddress ? [ownerAddress] : undefined,
    query: {
      enabled: !!ownerAddress,
    },
  });

  return { balance: balance ?? 0n, isLoading, refetch };
}
