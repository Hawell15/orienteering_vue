<template>
    <div class="index-page">
        <div class="index-hero">
            <div class="index-hero-inner">
                <div class="index-title-block">
                    <span class="index-eyebrow">🧭 Listă</span>
                    <h1 class="index-title">Competiții</h1>
                </div>
                <span class="index-count">{{ data.length }}</span>
                <div class="search-box">
                    <input type="text" v-model="filters.search" placeholder="Caută competiții…" class="search-input" />
                </div>
                <button v-if="isAdmin" class="add-btn" @click="createNew">＋ Adaugă competiție</button>
            </div>
        </div>

        <div class="filter-panel">
            <div class="filter-panel-head">
                <span class="filter-panel-title">⚙ Filtre</span>
                <button class="reset-btn" @click="resetFilters">Resetează</button>
            </div>
            <div class="filter-grid">
                <div class="filter-item">
                    <label for="country" class="label-filter">Țara</label>
                    <select id="country" v-model="filters.country" class="custom-select">
                        <option value="all">Toate</option>
                        <option value="international">Internaționale</option>
                        <option v-for="country in filterData.countries" :key="country" :value="country">{{ country }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="distance_type" class="label-filter">Tipul distanței</label>
                    <select id="distance_type" v-model="filters.distance_type" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="dt in filterData.distance_types" :key="dt" :value="dt">{{ dt }}</option>
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
                    <label class="label-filter">Indicatori</label>
                    <div class="checkbox-row">
                        <label class="checkbox-pill" :class="{ checked: filters.wre === true || filters.wre === 'true' }">
                            <input type="checkbox" v-model="filters.wre" /> WRE
                        </label>
                        <label class="checkbox-pill" :class="{ checked: filters.ecn === true || filters.ecn === 'true' }">
                            <input type="checkbox" v-model="filters.ecn" /> ECN
                        </label>
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
                <div>Nu s-au găsit competiții. Modifică filtrele sau adaugă una nouă.</div>
            </div>
        </div>

        <Create ref="modal" @save="saveCompetition" />
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
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc",
    "date[from]": "2000-01-01",
    "date[to]": "2100-01-01",
    "search": "",
    "country": "all",
    "distance_type": "all",
    "wre": "false",
    "ecn": "false"
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
        if (value === "false" || value === false) return;

        if (key !== 'search' && (value === "" || value === null)) {
            value = DEFAULT_FILTERS[key];
        }

        cleanParams[key] = value;
    });

    try {
        const res = await axios.get('/competitions.json', { params: cleanParams });
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

function orderTable(sortKey) {
    const isCurrentSort = filters["sorting[sort_by]"] === sortKey;
    const currentDir = filters["sorting[direction]"];

    filters["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters["sorting[sort_by]"] = sortKey;
}

async function getFiltersData() {
    const res = await axios.get('/competitions/filters.json')
    filterData.value = res.data
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
    getData();
}

function createNew() {
    modal.value.createNew()
}

function saveCompetition() {
    filters["sorting[sort_by]"] = "created_at"
    filters["sorting[direction]"] = "desc"
}
</script>

<style scoped src="../shared/index.css"></style>
