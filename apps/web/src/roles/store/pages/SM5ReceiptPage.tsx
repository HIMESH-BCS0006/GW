import React, { useEffect, useRef, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
  ArrowLeft,
  Camera,
  CheckCircle2,
  FileCheck,
  Loader2,
  ScanLine,
  ShieldCheck,
  Sparkles,
  TriangleAlert,
  Truck,
} from 'lucide-react';
import { Html5Qrcode } from 'html5-qrcode';
import { useOrder } from '../api/hooks';
import { useClientOpId } from '../hooks/useClientOpId';
import { apiClient, ApiError } from '../../../shared/api/client';
import { LoadingState } from '../../../shared/components/LoadingState';
import { ErrorState } from '../../../shared/components/ErrorState';

type Outcome = 'full' | 'discrepancy';
type DiscrepancyCategory = 'short' | 'damaged' | 'wrong_item' | 'temperature';

interface DriverHandoverPayload {
  version?: number;
  type?: string;
  stop_id?: string;
  trip_id?: string;
  trip_no?: number | string;
  vehicle_id?: string;
  order_id?: string;
  sequence?: number;
  outlet_id?: string;
  outlet_name?: string;
  district?: string;
  ordered_units?: number;
}

const CATEGORY_LABELS: Record<DiscrepancyCategory, string> = {
  short: 'Short delivery',
  damaged: 'Damaged / leaking',
  wrong_item: 'Wrong item',
  temperature: 'Temperature problem',
};

const RECEIPT_SCANNER_ID = 'receipt-qr-scanner';

function isAlreadyConfirmed(error: unknown) {
  return error instanceof ApiError && (
    error.code === 'ALREADY_CONFIRMED' ||
    error.code === 'RECEIPT_ALREADY_RECORDED' ||
    error.code === 'INVALID_TRANSITION'
  );
}

function parseDriverPayload(raw: string): DriverHandoverPayload | null {
  try {
    let clean = raw.trim();
    if (clean.startsWith('WAYPOINT-DRIVER-HANDOVER:')) {
      clean = clean.replace('WAYPOINT-DRIVER-HANDOVER:', '');
    }
    const parsed = JSON.parse(clean);
    return typeof parsed === 'object' && parsed !== null ? parsed : null;
  } catch {
    return null;
  }
}

export const SM5ReceiptPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const { data: order, isLoading, isError, error, refetch } = useOrder(id);
  const [outcome, setOutcome] = useState<Outcome>('full');
  const [category, setCategory] = useState<DiscrepancyCategory>('short');
  const [note, setNote] = useState('');
  const [submitError, setSubmitError] = useState<unknown>(null);
  const [confirmed, setConfirmed] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [scannedQr, setScannedQr] = useState<string | null>(null);
  const [scannedPayload, setScannedPayload] = useState<DriverHandoverPayload | null>(null);
  const [scannerError, setScannerError] = useState<string | null>(null);
  const scannerRef = useRef<Html5Qrcode | null>(null);
  const [getClientOpId, resetClientOpId] = useClientOpId();

  const orderWithReceipt = order as (typeof order & { receipt_status?: string }) | undefined;
  const alreadyConfirmed = confirmed || orderWithReceipt?.receipt_status === 'CONFIRMED' || order?.status === 'DELIVERED';

  useEffect(() => {
    if (alreadyConfirmed) return undefined;

    const scanner = new Html5Qrcode(RECEIPT_SCANNER_ID);
    scannerRef.current = scanner;
    let active = true;

    scanner.start(
      { facingMode: 'environment' },
      { fps: 10, qrbox: { width: 220, height: 220 } },
      (decodedText) => {
        if (!active) return;
        setScannedQr(decodedText);
        const parsed = parseDriverPayload(decodedText);
        if (parsed) setScannedPayload(parsed);
        setScannerError(null);
        void scanner.stop().catch(() => undefined);
      },
      () => undefined,
    ).catch(() => {
      if (active) setScannerError('Camera unavailable or permission denied. You can simulate scan or confirm receipt below.');
    });

    return () => {
      active = false;
      if (scannerRef.current?.isScanning) {
        void scannerRef.current.stop().catch(() => undefined);
      }
      scannerRef.current?.clear();
      scannerRef.current = null;
    };
  }, [alreadyConfirmed]);

  const simulateDriverScan = () => {
    if (!order) return;
    const simulated: DriverHandoverPayload = {
      version: 1,
      type: 'stop_handover',
      stop_id: order.stop_id || `STOP-${order.id}-1`,
      trip_id: order.trip_id || 'TRIP-DEMO-01',
      trip_no: 1,
      vehicle_id: 'V-WAYPOINT-01',
      order_id: order.id,
      sequence: 1,
      outlet_id: order.outlet_id,
      ordered_units: order.order_units,
    };
    setScannedPayload(simulated);
    setScannedQr(`WAYPOINT-DRIVER-HANDOVER:${JSON.stringify(simulated)}`);
    setScannerError(null);
  };

  async function submitReceipt(event: React.FormEvent) {
    event.preventDefault();
    if (!order || alreadyConfirmed) return;
    if (outcome === 'discrepancy' && !note.trim()) {
      setSubmitError(new Error('A discrepancy note is required.'));
      return;
    }

    const effectiveStopId = scannedPayload?.stop_id || order.stop_id || order.id;

    setIsSubmitting(true);
    setSubmitError(null);
    const receiptNote = outcome === 'discrepancy'
      ? `[Category: ${CATEGORY_LABELS[category]}] ${note.trim()}`
      : note.trim() || undefined;

    try {
      await apiClient.recordReceipt(effectiveStopId, {
        outcome,
        note: receiptNote,
        client_op_id: getClientOpId(),
      });
      resetClientOpId();
      setConfirmed(true);
    } catch (submitErr) {
      if (isAlreadyConfirmed(submitErr)) {
        setConfirmed(true);
      } else {
        setSubmitError(submitErr);
      }
    } finally {
      setIsSubmitting(false);
    }
  }

  if (isLoading) return <div className="p-4 lg:p-6"><LoadingState message="Loading receipt details…" /></div>;
  if (isError) return <div className="p-4 lg:p-6"><ErrorState error={error} title="Could not load receipt details" onRetry={() => refetch()} /></div>;
  if (!order) return <div className="p-4 lg:p-6"><ErrorState error={new Error('Order not found')} title="Order not found" /></div>;

  return (
    <div className="p-4 lg:p-6">
      <div className="mx-auto max-w-3xl space-y-5">
        <div className="flex items-center gap-3 border-b border-slate-200 pb-4">
          <Link to={`/store/orders/${order.id}`} aria-label="Back to order" className="rounded-full p-2 text-slate-600 hover:bg-slate-100">
            <ArrowLeft className="h-5 w-5" />
          </Link>
          <div>
            <h1 className="text-xl font-bold text-slate-900">Confirm Receipt &amp; Driver Handover</h1>
            <p className="text-sm text-slate-500">
              Order <span className="font-mono font-bold">{order.id}</span> • Delivery Stop <span className="font-mono font-bold">{order.stop_id ?? 'Auto-matched'}</span>
            </p>
          </div>
        </div>

        {alreadyConfirmed ? (
          <section data-testid="receipt-already-confirmed" className="rounded-xl border border-emerald-200 bg-emerald-50 p-8 text-center">
            <CheckCircle2 className="mx-auto h-14 w-14 text-emerald-600" />
            <h2 className="mt-3 text-2xl font-bold text-emerald-950">Delivery Received &amp; Confirmed!</h2>
            <p className="mt-2 text-sm text-emerald-800">
              The order receipt has been recorded and marked as <strong>Delivered</strong> across Store Manager, Dispatcher, and Driver views.
            </p>
            <div className="mt-6 flex flex-wrap justify-center gap-3">
              <Link to={`/store/orders/${order.id}`} className="rounded-lg bg-emerald-700 px-5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-emerald-800 transition-colors">
                View Order Tracking
              </Link>
              <Link to="/store/orders" className="rounded-lg border border-slate-300 bg-white px-5 py-2.5 text-sm font-semibold text-slate-700 shadow-sm hover:bg-slate-50 transition-colors">
                Back to Orders
              </Link>
            </div>
          </section>
        ) : (
          <form onSubmit={submitReceipt} className="space-y-5 rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-center gap-3 rounded-lg bg-slate-50 p-4">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-brand-100 text-brand-700">
                <FileCheck className="h-5 w-5" />
              </div>
              <div>
                <h2 className="font-bold text-slate-900">Step 1: Driver Handover QR Code</h2>
                <p className="text-xs text-slate-500">Scan the Handover QR code displayed on the driver&apos;s mobile app to verify delivery authorization.</p>
              </div>
            </div>

            {/* QR Scanner Area */}
            <div className="rounded-lg border border-slate-200 p-4">
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2 text-sm font-bold text-slate-800">
                  <ScanLine className="h-4 w-4 text-emerald-700" /> Driver Handover QR Scanner
                </div>
                <button
                  type="button"
                  onClick={simulateDriverScan}
                  className="flex items-center gap-1.5 rounded-lg border border-emerald-300 bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-800 hover:bg-emerald-100 transition-colors"
                >
                  <Sparkles className="h-3.5 w-3.5" /> Simulate Driver QR Scan
                </button>
              </div>

              <div className="mt-3 overflow-hidden rounded-lg bg-slate-950 p-2">
                <div id={RECEIPT_SCANNER_ID} className="min-h-[180px]" />
              </div>

              {scannedPayload ? (
                <div className="mt-3 rounded-lg border border-emerald-300 bg-emerald-50 p-3.5">
                  <div className="flex items-center gap-2 font-bold text-emerald-900 text-sm">
                    <ShieldCheck className="h-4 w-4 text-emerald-700" />
                    Driver Handover Verified
                  </div>
                  <div className="mt-2.5 grid grid-cols-2 gap-2 text-xs sm:grid-cols-4">
                    <div className="rounded bg-white p-2 border border-emerald-100">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Vehicle</span>
                      <p className="font-bold text-slate-800 mt-0.5">{scannedPayload.vehicle_id || 'Assigned'}</p>
                    </div>
                    <div className="rounded bg-white p-2 border border-emerald-100">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Trip</span>
                      <p className="font-bold text-slate-800 mt-0.5">{scannedPayload.trip_no ? `Trip #${scannedPayload.trip_no}` : (scannedPayload.trip_id || '--')}</p>
                    </div>
                    <div className="rounded bg-white p-2 border border-emerald-100">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Stop Seq</span>
                      <p className="font-bold text-slate-800 mt-0.5">{scannedPayload.sequence ? `Stop #${scannedPayload.sequence}` : 'Stop #1'}</p>
                    </div>
                    <div className="rounded bg-white p-2 border border-emerald-100">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Manifest Units</span>
                      <p className="font-bold text-slate-800 mt-0.5">{scannedPayload.ordered_units ?? order.order_units}</p>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="mt-2 flex items-start gap-2 text-xs text-slate-600">
                  <Camera className="h-4 w-4 shrink-0 text-emerald-700 mt-0.5" />
                  <span>{scannedQr ? `Scanned code: ${scannedQr}` : 'Point camera at the driver\'s handover QR code, or click Simulate Driver QR Scan above.'}</span>
                </div>
              )}

              {scannerError && <p className="mt-2 text-xs text-amber-700">{scannerError}</p>}
            </div>

            {/* Step 2: Intake Verification */}
            <div className="border-t border-slate-100 pt-3">
              <h3 className="text-sm font-bold text-slate-800 mb-2">Step 2: Receiving Outcome</h3>
              <div className="grid gap-3 sm:grid-cols-2">
                <label className={`cursor-pointer rounded-lg border p-4 ${outcome === 'full' ? 'border-emerald-500 bg-emerald-50' : 'border-slate-200 hover:bg-slate-50'}`}>
                  <input type="radio" name="outcome" checked={outcome === 'full'} onChange={() => setOutcome('full')} />
                  <span className="ml-2 text-sm font-bold text-slate-900">Received in full</span>
                  <p className="ml-6 mt-1 text-xs text-slate-500">All {order.order_units} units received in good order.</p>
                </label>
                <label className={`cursor-pointer rounded-lg border p-4 ${outcome === 'discrepancy' ? 'border-orange-500 bg-orange-50' : 'border-slate-200 hover:bg-slate-50'}`}>
                  <input type="radio" name="outcome" checked={outcome === 'discrepancy'} onChange={() => setOutcome('discrepancy')} />
                  <span className="ml-2 text-sm font-bold text-slate-900">Report discrepancy</span>
                  <p className="ml-6 mt-1 text-xs text-slate-500">Damaged, missing, or short delivery detected.</p>
                </label>
              </div>

              {outcome === 'discrepancy' && (
                <div className="mt-4 rounded-lg border border-orange-200 bg-orange-50 p-4">
                  <p className="flex items-center gap-2 text-sm font-bold text-orange-900">
                    <TriangleAlert className="h-4 w-4" /> Discrepancy details
                  </p>
                  <div className="mt-3 grid gap-2 sm:grid-cols-2">
                    {(Object.keys(CATEGORY_LABELS) as DiscrepancyCategory[]).map((key) => (
                      <label key={key} className="flex items-center gap-2 rounded-md bg-white px-3 py-2 text-sm">
                        <input type="radio" name="category" checked={category === key} onChange={() => setCategory(key)} />
                        {CATEGORY_LABELS[key]}
                      </label>
                    ))}
                  </div>
                </div>
              )}

              <label className="mt-4 block text-sm font-semibold text-slate-700">
                {outcome === 'discrepancy' ? 'Discrepancy note' : 'Receiving note'}
                {outcome === 'discrepancy' && <span className="text-red-600"> *</span>}
                <textarea
                  value={note}
                  onChange={(event) => setNote(event.target.value)}
                  rows={3}
                  className="mt-1 block w-full rounded-lg border border-slate-300 p-3 text-sm font-normal focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500"
                  placeholder={outcome === 'discrepancy' ? 'Describe what was missing or damaged' : 'Optional note (e.g. driver arrived on time)'}
                />
              </label>
            </div>

            {submitError !== null && <div className="mt-4"><ErrorState error={submitError} title="Receipt could not be submitted" /></div>}

            <button
              type="submit"
              disabled={isSubmitting}
              className="mt-5 flex w-full items-center justify-center gap-2 rounded-lg bg-[#12665a] px-4 py-3.5 text-sm font-bold text-white shadow hover:bg-[#0e4e45] disabled:cursor-not-allowed disabled:bg-slate-300 transition-colors"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" /> Submitting receipt…
                </>
              ) : (
                <>
                  <CheckCircle2 className="h-4 w-4" /> Confirm Receipt &amp; Mark Delivered
                </>
              )}
            </button>
          </form>
        )}
      </div>
    </div>
  );
};
