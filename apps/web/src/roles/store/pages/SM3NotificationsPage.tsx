import React from 'react';
import { AlertTriangle, Bell, CalendarClock, CheckCircle2, ChevronRight, Info, Loader2 } from 'lucide-react';
import { useNotifications, useMarkNotificationRead } from '../api/hooks';
import { LoadingState } from '../../../shared/components/LoadingState';
import { ErrorState } from '../../../shared/components/ErrorState';

function noticeData(notification: any) {
  const data = notification.data ?? notification.details ?? notification.payload ?? {};
  const eventType = notification.type ?? notification.event_type ?? data.type ?? notification.event_id ?? 'notice';
  const reason = notification.message ?? notification.reason_text ?? notification.reason ?? data.reason_text ?? data.reason;
  const reasonClass = notification.reason_class ?? data.reason_class;
  const consequence = notification.consequence_text ?? data.consequence_text ?? data.consequence;
  const expectedDate = notification.resolved_to_date ?? notification.new_expected_date ?? data.resolved_to_date ?? data.new_expected_date ?? data.delivery_date;
  const isCancelled = String(eventType).toLowerCase().includes('cancel') || String(notification.message).toLowerCase().includes('cancel');
  const isDeferral = !isCancelled && (String(eventType).toLowerCase().includes('defer') || Boolean(notification.reason_text || reasonClass));
  const isEtaChange = !isCancelled && (String(eventType).toLowerCase().includes('eta') || String(eventType).toLowerCase().includes('retry'));

  return {
    title: isCancelled ? 'Order Cancelled by Dispatcher' : isDeferral ? 'Delivery date changed' : isEtaChange ? 'Delivery ETA updated' : 'Store delivery notice',
    reason: notification.message || reason || (isEtaChange ? 'The delivery plan was updated after a retry.' : 'A new update is available for this store order.'),
    reasonClass: reasonClass || (isDeferral ? 'Operational notice' : undefined),
    consequence,
    expectedDate,
    isCancelled,
    isDeferral,
    isEtaChange,
  };
}

export const SM3NotificationsPage: React.FC = () => {
  const { data: notifications, isLoading, isError, error, refetch } = useNotifications();
  const markRead = useMarkNotificationRead();

  if (isLoading) return <div className="p-4 lg:p-6"><LoadingState message="Loading notices…" /></div>;
  if (isError) return <div className="p-4 lg:p-6"><ErrorState error={error} title="Could not load notices" onRetry={() => refetch()} /></div>;

  const notices = notifications ?? [];

  function openNotice(notification: any) {
    if (!notification.read_at && notification.id) {
      markRead.mutate(notification.id);
    }
  }

  return (
    <div className="p-4 lg:p-6">
      <div className="mx-auto max-w-4xl space-y-5">
        <div className="flex items-center gap-3 border-b border-slate-200 pb-4">
          <div className="flex h-11 w-11 items-center justify-center rounded-lg bg-brand-100 text-brand-700"><Bell className="h-5 w-5" /></div>
          <div><h1 className="text-xl font-bold text-slate-900">Deferred Notices & Notifications</h1><p className="text-sm text-slate-500">Delivery changes, deferral reasons, and expected dates.</p></div>
        </div>

        {notices.length === 0 ? (
          <div className="rounded-xl border border-dashed border-slate-300 bg-white p-10 text-center text-slate-500"><Bell className="mx-auto h-8 w-8 text-slate-300" /><p className="mt-3 font-semibold text-slate-700">No notices</p><p className="mt-1 text-sm">New delivery updates will appear here.</p></div>
        ) : (
          <div className="space-y-3">
            {notices.map((notification: any) => {
              const notice = noticeData(notification);
              const unread = !notification.read_at;
              const Icon = notice.isCancelled ? AlertTriangle : notice.isDeferral ? AlertTriangle : notice.isEtaChange ? CalendarClock : Info;
              return (
                <article key={notification.id} onClick={() => openNotice(notification)} className={`cursor-pointer rounded-xl border p-4 shadow-sm transition-colors ${notice.isCancelled ? 'border-rose-200 bg-rose-50/50 hover:bg-rose-50' : unread ? 'border-amber-200 bg-amber-50/60 hover:bg-amber-50' : 'border-slate-200 bg-white hover:bg-slate-50'}`}>
                  <div className="flex items-start gap-3">
                    <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${notice.isCancelled ? 'bg-rose-100 text-rose-700' : unread ? 'bg-amber-100 text-amber-700' : 'bg-emerald-100 text-emerald-700'}`}><Icon className="h-5 w-5" /></div>
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <h2 className="font-bold text-slate-900">{notice.title}</h2>
                        {notice.isCancelled ? (
                          <span className="rounded-full bg-rose-200 px-2 py-0.5 text-[10px] font-bold uppercase text-rose-900">Cancelled</span>
                        ) : unread ? (
                          <span className="rounded-full bg-amber-200 px-2 py-0.5 text-[10px] font-bold uppercase text-amber-900">Unread</span>
                        ) : null}
                      </div>
                      <p className="mt-2 text-sm text-slate-700">{notice.reason}</p>
                      {notice.reasonClass && <p className="mt-2 text-xs font-semibold uppercase tracking-wide text-slate-500">Reason class: {notice.reasonClass}</p>}
                      {notice.consequence && <p className="mt-2 rounded-lg bg-white/80 px-3 py-2 text-xs text-slate-700"><span className="font-bold">Consequence: </span>{notice.consequence}</p>}
                      {notice.expectedDate && <p className="mt-2 flex items-center gap-1 text-xs font-semibold text-emerald-800"><CalendarClock className="h-3.5 w-3.5" /> Expected delivery: {notice.expectedDate}</p>}
                      <a href="tel:+94112948110" onClick={(event) => event.stopPropagation()} className="mt-3 inline-flex items-center gap-1 text-xs font-bold text-emerald-800 hover:underline">Call dispatcher <ChevronRight className="h-3.5 w-3.5" /></a>
                    </div>
                    <div className="text-slate-400">{markRead.isPending && unread ? <Loader2 className="h-4 w-4 animate-spin" /> : unread ? <CheckCircle2 className="h-4 w-4" /> : null}</div>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
