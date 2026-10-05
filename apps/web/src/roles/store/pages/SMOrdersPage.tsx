import React, { useMemo, useState } from 'react';
import { ClipboardList } from 'lucide-react';
import { useOrders } from '../api/hooks';
import { LoadingState } from '../../../shared/components/LoadingState';
import { ErrorState } from '../../../shared/components/ErrorState';
import { EmptyState } from '../../../shared/components/EmptyState';
import { OrderListItem } from './SM1HomePage';
import type { Order } from '../types';

type Filter = 'all' | 'progress' | 'done';
const DONE = ['DELIVERED', 'PARTIALLY_DELIVERED'];
const TERMINAL = [...DONE, 'CANCELLED'];

export const SMOrdersPage: React.FC = () => {
  const [filter, setFilter] = useState<Filter>('all');
  const { data: orders, isLoading, isError, error, refetch } = useOrders();
  const sorted = useMemo(() => orders ? [...orders].sort((a, b) => a.delivery_date.localeCompare(b.delivery_date)) : [], [orders]);
  const visible = sorted.filter((order: Order) => filter === 'all' ? true : filter === 'done' ? DONE.includes(order.status) : !TERMINAL.includes(order.status) && order.status !== 'DEFERRED');

  if (isLoading) return <div className="p-4 lg:p-6"><LoadingState message="Loading orders…" /></div>;
  return <div className="mx-auto w-full max-w-5xl space-y-5 p-4 lg:px-14 lg:py-8">
    <div><p className="text-xs font-bold uppercase tracking-[0.18em] text-slate-500">Store receiving manifest</p><h1 className="mt-1 text-2xl font-bold text-slate-900">Orders</h1></div>
    <div role="tablist" className="flex w-fit gap-1 rounded-lg bg-[#F4F1E6] p-1 text-[11px] font-semibold">{(['all', 'progress', 'done'] as Filter[]).map((key) => <button key={key} type="button" role="tab" aria-selected={filter === key} onClick={() => setFilter(key)} className={`rounded-md px-3 py-1.5 ${filter === key ? 'bg-white shadow-sm' : 'text-slate-600'}`}>{key === 'all' ? 'All orders' : key === 'progress' ? 'In progress' : 'Completed'} ({key === 'all' ? sorted.length : key === 'done' ? sorted.filter((order) => DONE.includes(order.status)).length : sorted.filter((order) => !TERMINAL.includes(order.status) && order.status !== 'DEFERRED').length})</button>)}</div>
    {isError ? <ErrorState error={error} title="Could not load orders" onRetry={() => refetch()} /> : sorted.length === 0 ? <EmptyState icon={<ClipboardList className="h-10 w-10" />} title="No orders yet" description="Your store orders will appear here." /> : <ul data-testid="orders-list" className="space-y-2.5">{visible.map((order) => <OrderListItem key={order.id} order={order} />)}</ul>}
  </div>;
};
