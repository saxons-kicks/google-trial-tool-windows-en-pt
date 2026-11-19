// frida-auto-trial.js — Avaliação Google AI Ultra: descobrir + ativar
// Blog: https://blog.caowo.de/
// Loja de chaves: https://faka.cdkey.si/
//
// Uso:
//   frida -H 127.0.0.1:<PORTA> -p <PID> -l frida-auto-trial.js
//
// Tag do logcat: AutoTrial
// O script shell auto-trial.sh altera as linhas de CONFIG abaixo.

// ===== CONFIG (auto-trial.sh altera estas variáveis) =====
var MODE = "activate";           // "list" | "activate"
var TARGET_PRODUCT = "auto";     // "auto" | "g1.play.ai.pro" | "g1.play.20tb"
var PREFER_DURATION = "longest"; // "longest" | "1mo" | "3mo" | "6mo" | "12mo"
var MODULE_APK = "/data/local/tmp/module.apk";
// ===== FIM CONFIG =====

Java.perform(function() {
    var TAG = "AutoTrial";
    var Log = Java.use("android.util.Log");
    var context = Java.use("android.app.ActivityThread").currentApplication().getApplicationContext();
    var Activity = Java.use("android.app.Activity");
    var ArrayList = Java.use("java.util.ArrayList");
    var List = Java.use("java.util.List");
    var Handler = Java.use("android.os.Handler");
    var Looper = Java.use("android.os.Looper");

    Log.i(TAG, "=== AUTO_TRIAL_START mode=" + MODE + " target=" + TARGET_PRODUCT + " prefer=" + PREFER_DURATION + " ===");

    // --- Carregar BillingClient a partir do APK de módulo ---
    var DexClassLoader = Java.use("dalvik.system.DexClassLoader");
    var dexLoader = DexClassLoader.$new(
        MODULE_APK,
        context.getCodeCacheDir().getAbsolutePath(),
        null,
        context.getClassLoader()
    );
    Java.classFactory.loader = dexLoader;

    var BillingClient = Java.use("com.android.billingclient.api.BillingClient");
    var QueryProductDetailsParams = Java.use("com.android.billingclient.api.QueryProductDetailsParams");
    var QpdProduct = Java.use("com.android.billingclient.api.QueryProductDetailsParams$Product");
    var BillingFlowParams = Java.use("com.android.billingclient.api.BillingFlowParams");
    var BfpProductDetailsParams = Java.use("com.android.billingclient.api.BillingFlowParams$ProductDetailsParams");
    var PurchasesUpdatedListener = Java.use("com.android.billingclient.api.PurchasesUpdatedListener");
    var BillingClientStateListener = Java.use("com.android.billingclient.api.BillingClientStateListener");
    var ProductDetailsResponseListener = Java.use("com.android.billingclient.api.ProductDetailsResponseListener");
    var ProductDetails = Java.use("com.android.billingclient.api.ProductDetails");
    var SubscriptionOfferDetails = Java.use("com.android.billingclient.api.ProductDetails$SubscriptionOfferDetails");
    var PricingPhase = Java.use("com.android.billingclient.api.ProductDetails$PricingPhase");

    var PRODUCTS = ["g1.play.ai.pro", "g1.play.20tb", "g1.play.2tb.ai", "g1.2tb.ai.subs_variant", "g1.ai.pro", "g1.30tb", "g1.2tb.ai"];

    var DUR = { "P1M": 1, "P3M": 3, "P6M": 6, "P1Y": 12 };
    var ALIAS = { "1mo": "P1M", "3mo": "P3M", "6mo": "P6M", "12mo": "P1Y" };

    var GLOBAL_REFS = [];
    function keepAlive(obj) {
        GLOBAL_REFS.push(obj);
        return obj;
    }

    // --- Retorno de chamada da compra ---
    var PLClass = keepAlive(Java.registerClass({
        name: "com.frida.auto.PL",
        implements: [PurchasesUpdatedListener],
        methods: {
            onPurchasesUpdated: function(br, purchases) {
                var code = br.getResponseCode();
                if (code === 0 && purchases != null) {
                    var pl = Java.cast(purchases, List);
                    for (var i = 0; i < pl.size(); i++) {
                        Log.i(TAG, "PURCHASE: " + String(pl.get(i).toString()).substring(0, 200));
                    }
                    Log.i(TAG, "=== TRIAL_ACTIVATED ===");
                } else if (code === 1) {
                    Log.i(TAG, "=== USER_CANCELLED ===");
                } else if (code === 7) {
                    Log.i(TAG, "=== ITEM_ALREADY_OWNED ===");
                } else {
                    Log.i(TAG, "=== PURCHASE_FAILED code=" + code + " msg=" + br.getDebugMessage() + " ===");
                }
            }
        }
    }));
    var purchaseListener = keepAlive(PLClass.$new());

    var builder = BillingClient.newBuilder(context).setListener(purchaseListener);
    try {
        var PendingPurchasesParams = Java.use("com.android.billingclient.api.PendingPurchasesParams");
        builder = builder.enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build());
    } catch (e) {
        builder = builder.enablePendingPurchases();
    }
    var bc = keepAlive(builder.build());

    var SLClass = keepAlive(Java.registerClass({
        name: "com.frida.auto.SL",
        implements: [BillingClientStateListener],
        methods: {
            onBillingSetupFinished: function(result) {
                if (result.getResponseCode() !== 0) {
                    Log.e(TAG, "=== CONNECT_FAILED code=" + result.getResponseCode() + " ===");
                    return;
                }
                Log.i(TAG, "BillingClient connected");

                Java.classFactory.loader = null;
                var mainHandler = Handler.$new(Looper.getMainLooper());
                Java.classFactory.loader = dexLoader;

                var Runnable = Java.use("java.lang.Runnable");
                var QRClass = keepAlive(Java.registerClass({
                    name: "com.frida.auto.QR",
                    implements: [Runnable],
                    methods: { run: function() { doQuery(); } }
                }));
                var queryRunnable = keepAlive(QRClass.$new());
                mainHandler.post(queryRunnable);
            },
            onBillingServiceDisconnected: function() {
                Log.w(TAG, "BillingClient desconectado");
            }
        }
    }));
    var stateListener = keepAlive(SLClass.$new());

    function doQuery() {
        var prodList = ArrayList.$new();
        for (var i = 0; i < PRODUCTS.length; i++) {
            prodList.add(QpdProduct.newBuilder()
                .setProductId(PRODUCTS[i]).setProductType("subs").build());
        }
        var params = QueryProductDetailsParams.newBuilder().setProductList(prodList).build();

        var PDLClass = keepAlive(Java.registerClass({
            name: "com.frida.auto.PDL",
            implements: [ProductDetailsResponseListener],
            methods: { onProductDetailsResponse: function(br, pdList) {
                try {
                    onProducts(br, pdList);
                } catch (e) {
                    Log.e(TAG, "=== LAUNCH_ERROR " + e + " ===");
                }
            } }
        }));
        var pdl = keepAlive(PDLClass.$new());
        bc.queryProductDetailsAsync(params, pdl);
    }

    function onProducts(br, pdList) {
        var rawList = pdList;
        try {
            var QueryProductDetailsResult = Java.use("com.android.billingclient.api.QueryProductDetailsResult");
            if (QueryProductDetailsResult.class.isInstance(pdList)) {
                rawList = Java.cast(pdList, QueryProductDetailsResult).getProductDetailsList();
            }
        } catch (e) {}
        var list = Java.cast(rawList, List);
        Log.i(TAG, "Products found: " + list.size());

        // Coletar todas as ofertas de avaliação em todos os produtos
        var trials = [];   // [{product, offerId, duration, months, pd, offer}]

        for (var i = 0; i < list.size(); i++) {
            var pd = Java.cast(list.get(i), ProductDetails);
            var pid = String(pd.getProductId());
            Log.i(TAG, "");
            Log.i(TAG, "PRODUCT " + pid + " — " + pd.getTitle());

            var offers = pd.getSubscriptionOfferDetails();
            if (offers == null) { Log.i(TAG, "  (sem ofertas)"); continue; }
            var ol = Java.cast(offers, List);

            for (var j = 0; j < ol.size(); j++) {
                var o = Java.cast(ol.get(j), SubscriptionOfferDetails);
                var oid = o.getOfferId();
                var phases = Java.cast(o.getPricingPhases().getPricingPhaseList(), List);

                // Tags
                var tags = Java.cast(o.getOfferTags(), List);
                var tagStr = "";
                for (var t = 0; t < tags.size(); t++) tagStr += (t > 0 ? "," : "") + tags.get(t);

                var hasTrial = false;
                var trialPeriod = "";
                for (var k = 0; k < phases.size(); k++) {
                    var ph = Java.cast(phases.get(k), PricingPhase);
                    var micros = ph.getPriceAmountMicros();
                    var free = (micros == 0 || String(micros) === "0");
                    var period = String(ph.getBillingPeriod());
                    Log.i(TAG, "  [" + j + "] Fase" + k + ": " + ph.getFormattedPrice()
                        + " × " + period + " (" + ph.getBillingCycleCount() + " ciclos)"
                        + (free ? " ★GRÁTIS★" : "")
                        + (k === 0 && oid != null ? " id=" + oid : "")
                        + (tagStr && k === 0 ? " tags=[" + tagStr + "]" : ""));
                    if (k === 0 && free && phases.size() > 1) {
                        hasTrial = true;
                        trialPeriod = period;
                    }
                }

                if (hasTrial) {
                    trials.push({ product: pid, offerId: String(oid),
                        duration: trialPeriod, months: DUR[trialPeriod] || 0,
                        pd: pd, offer: o });
                }
            }
        }

        // Resumo
        Log.i(TAG, "");
        Log.i(TAG, "TRIALS_FOUND " + trials.length);
        for (var i = 0; i < trials.length; i++) {
            var t = trials[i];
            Log.i(TAG, "  TRIAL " + t.product + " / " + t.offerId + " — " + t.months + " meses grátis");
        }

        if (trials.length === 0 || MODE === "list") {
            Log.i(TAG, "=== " + (trials.length === 0 ? "NO_TRIALS" : "LIST_COMPLETE") + " ===");
            return;
        }

        // --- Selecionar melhor avaliação ---
        // Filtrar pelo produto alvo
        var candidates = [];
        for (var i = 0; i < trials.length; i++) {
            if (TARGET_PRODUCT === "auto" || trials[i].product === TARGET_PRODUCT) {
                candidates.push(trials[i]);
            }
        }
        if (candidates.length === 0) {
            Log.e(TAG, "Nenhuma avaliação para alvo=" + TARGET_PRODUCT);
            Log.i(TAG, "=== SELECT_FAILED ===");
            return;
        }

        var selected = null;
        if (PREFER_DURATION === "longest") {
            selected = candidates[0];
            for (var i = 1; i < candidates.length; i++) {
                if (candidates[i].months > selected.months) selected = candidates[i];
            }
        } else {
            var wantPeriod = ALIAS[PREFER_DURATION] || PREFER_DURATION;
            for (var i = 0; i < candidates.length; i++) {
                if (candidates[i].duration === wantPeriod) { selected = candidates[i]; break; }
            }
            if (!selected) {
                Log.w(TAG, PREFER_DURATION + " não encontrado, usando a mais longa");
                selected = candidates[0];
                for (var i = 1; i < candidates.length; i++) {
                    if (candidates[i].months > selected.months) selected = candidates[i];
                }
            }
        }

        Log.i(TAG, "SELECTED " + selected.product + " / " + selected.offerId + " (" + selected.months + " meses)");
        Log.i(TAG, "Waiting for Activity to stabilize...");

        // --- Obter Activity ---
        var act = null;
        try {
            Java.classFactory.loader = null;
            var AT = Java.use("android.app.ActivityThread");
            var athread = AT.currentActivityThread();
            var acts = athread.mActivities.value;
            var ait = acts.values().iterator();
            while (ait.hasNext()) {
                var rec = ait.next();
                var af = rec.getClass().getDeclaredField("activity");
                af.setAccessible(true);
                var a = Java.cast(af.get(rec), Activity);
                if (!a.isFinishing() && !a.isDestroyed()) { act = a; break; }
            }
            Java.classFactory.loader = dexLoader;
        } catch(e) {
            Log.e(TAG, "Erro na Activity: " + e);
            Java.classFactory.loader = dexLoader;
            return;
        }
        if (!act) { Log.e(TAG, "=== NO_ACTIVITY ==="); return; }

        // --- Iniciar fluxo de cobrança na thread de UI ---
        var token = selected.offer.getOfferToken();
        var finalPd = selected.pd;
        var finalAct = act;
        var finalToken = token;

        Java.classFactory.loader = null;
        var launchHandler = Handler.$new(Looper.getMainLooper());
        Java.classFactory.loader = dexLoader;

        var LRClass = keepAlive(Java.registerClass({
            name: "com.frida.auto.LR",
            implements: [Java.use("java.lang.Runnable")],
            methods: {
                run: function() {
                    try {
                        // Buscar a Activity novamente na thread de UI para garantir que seja a atual
                        var uiAct = finalAct;
                        try {
                            Java.classFactory.loader = null;
                            var AT2 = Java.use("android.app.ActivityThread");
                            var at2 = AT2.currentActivityThread();
                            var acts2 = at2.mActivities.value;
                            var it2 = acts2.values().iterator();
                            while (it2.hasNext()) {
                                var r2 = it2.next();
                                var f2 = r2.getClass().getDeclaredField("activity");
                                f2.setAccessible(true);
                                var a2 = Java.cast(f2.get(r2), Activity);
                                if (!a2.isFinishing() && !a2.isDestroyed()) { uiAct = a2; break; }
                            }
                            Java.classFactory.loader = dexLoader;
                        } catch(ae) {
                            Java.classFactory.loader = dexLoader;
                        }

                        var pdp = BfpProductDetailsParams.newBuilder()
                            .setProductDetails(finalPd).setOfferToken(finalToken).build();
                        var pdpList = ArrayList.$new();
                        pdpList.add(pdp);
                        var flowParams = BillingFlowParams.newBuilder()
                            .setProductDetailsParamsList(pdpList).build();
                        var r = bc.launchBillingFlow(Java.cast(uiAct, Activity), flowParams);
                        Log.i(TAG, "BILLING_FLOW_LAUNCHED code=" + r.getResponseCode());
                    } catch(e) {
                        Log.e(TAG, "=== LAUNCH_ERROR " + e + " ===");
                    }
                }
            }
        }));
        var LaunchRunnable = keepAlive(LRClass.$new());
        // Aguardar 1,5s para permitir que a Activity renderize completamente antes de abrir a janela de cobrança
        launchHandler.postDelayed(LaunchRunnable, 1500);
    }

    bc.startConnection(stateListener);
});
setInterval(function(){}, 1000);
