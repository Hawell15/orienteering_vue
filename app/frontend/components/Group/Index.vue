<template>
    <div class="index-page">
        <div class="index-hero">
            <div class="index-hero-inner">
                <div class="index-title-block">
                    <span class="index-eyebrow">🏃 Listă</span>
                    <h1 class="index-title">Grupe</h1>
                </div>
                <span class="index-count">{{ data.length }}</span>
                <div class="search-box">
                    <input type="text" v-model="filters.search" placeholder="Caută grupe…" class="search-input" />
                </div>
                <button v-if="isAdmin" class="add-btn" @click="createNew">＋ Adaugă grupă</button>
            </div>
        </div>

        <div class="filter-panel">
            <div class="filter-panel-head">
                <span class="filter-panel-title">⚙ Filtre</span>
                <button class="reset-btn" @click="resetFilters">Resetează</button>
            </div>
            <div class="filter-grid">
                <div class="filter-item">
                    <label for="competition" class="label-filter">Competiția</label>
                    <select id="competition" v-model="filters.competition" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="c in filterData.competitions" :key="c.id" :value="c.id">{{ c.competition_display }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="clasa" class="label-filter">Clasa</label>
                    <select id="clasa" v-model="filters.clasa" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="cl in filterData.clase" :key="cl.id" :value="cl.id">{{ cl.category_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Data</label>
                    <div class="range-wrapper">
                        <input type="date" v-model="filters['date[from]']" class="custom-input" />
                        <span class="range-separator">—</span>
                        <input type="date" v-model="filters['date[to]']" class="custom-input" />
                    </div>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Număr rezultate</label>
                    <div class="range-wrapper">
                        <input type="number" v-model="filters['results_count[from]']" min="0" class="custom-input" placeholder="De la" />
                        <span class="range-separator">—</span>
                        <input type="number" v-model="filters['results_count[to]']" min="0" class="custom-input" placeholder="Până la" />
                    </div>
                </div>
            </div>
        </div>

        <div class="table-card">
            <div class="table-scroll">
                <Table :elements="data" @order="orderTable"></Table>
            </div>
            <div v-if="data.length === 0" class="empty-state">
                <div class="empty-state-icon">🔍</div>
                <div>Nu s-au găsit grupe.</div>
            </div>
        </div>

        <Create ref="modal" @save="saveGroup" />
    </div>
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from '@/axios'
import Create from './Create.vue'
import Table from './Table.vue'
import { isAdmin } from '@/currentUser'
const data = ref([])
const filterData = ref({})
const modal = ref(null)

const DEFAULT_FILTERS = {
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc",
    "results_count[from]": 0,
    "results_count[to]": 9999,
    "date[from]": "2000-01-01",
    "date[to]": "2100-01-01",
    "competition": "all",
    "clasa": "all"
}

const filters = reactive({ ...DEFAULT_FILTERS });

let debounceTimeout = null;

watch(
    filters,
    () => {
        clearTimeout(debounceTimeout);
        debounceTimeout = setTimeout(() => {
            getData();
        }, 400);
    }, { deep: true }
);

async function getData() {
    const cleanParams = {};

    const rangePairs = [
        { from: "results_count[from]", to: "results_count[to]" },
        { from: "date[from]", to: "date[to]" },
    ];

    const keysToSkip = new Set();

    if (filters.search === "") {
        keysToSkip.add("search")
    }

    rangePairs.forEach(pair => {
        const currentFrom = filters[pair.from];
        const currentTo = filters[pair.to];
        const defaultFrom = DEFAULT_FILTERS[pair.from];
        const defaultTo = DEFAULT_FILTERS[pair.to];

        if (currentFrom === defaultFrom && currentTo === defaultTo) {
            keysToSkip.add(pair.from);
            keysToSkip.add(pair.to);
        }
    });

    Object.keys(filters).forEach(key => {
        let value = filters[key];

        if (keysToSkip.has(key)) return;
        if (value === "all") return;

        if (key !== 'search' && (value === "" || value === null)) {
            value = DEFAULT_FILTERS[key];
        }

        cleanParams[key] = value;
    });

    try {
        const res = await axios.get('/groups.json', { params: cleanParams });
        data.value = res.data;

        const queryString = new URLSearchParams(cleanParams).toString();
        const urlPrefix = window.location.pathname;
        const newUrl = queryString ? `${urlPrefix}?${queryString}` : urlPrefix;

        window.history.replaceState({}, '', newUrl);
    } catch (error) {
        console.error("API Error:", error);
    }
}

onMounted(() => {
    getFiltersData()
    const urlParams = new URLSearchParams(window.location.search);

    urlParams.forEach((value, key) => {
        if (key in filters) {
            const isNumber = typeof DEFAULT_FILTERS[key] === 'number';
            filters[key] = isNumber ? Number(value) : value;
        }
    });
    getData();
})

async function getFiltersData() {
    const res = await axios.get('groups/filters.json')
    filterData.value = res.data
}

function orderTable(sortKey) {
    const isCurrentSort = filters["sorting[sort_by]"] === sortKey;
    const currentDir = filters["sorting[direction]"];

    filters["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters["sorting[sort_by]"] = sortKey;
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
    getData();
}

function createNew() {
    modal.value.createNew()
}

function saveGroup() {
    filters["sorting[sort_by]"] = "created_at"
    filters["sorting[direction]"] = "desc"
}
</script>

<style scoped src="../shared/index.css"></style>
