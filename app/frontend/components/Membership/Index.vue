<template>
    <div class="index-page">
        <div class="index-hero">
            <div class="index-hero-inner">
                <div class="index-title-block">
                    <span class="index-eyebrow">🪪 Listă</span>
                    <h1 class="index-title">Afilieri</h1>
                </div>
                <span class="index-count">{{ data.length }}</span>
                <div class="search-box">
                    <input type="text" v-model="filters.search" placeholder="Caută afilieri…" class="search-input" />
                </div>
                <button v-if="isAdmin" class="add-btn" @click="createNew">＋ Adaugă afiliere</button>
            </div>
        </div>

        <div class="filter-panel">
            <div class="filter-panel-head">
                <span class="filter-panel-title">⚙ Filtre</span>
                <button class="reset-btn" @click="resetFilters">Resetează</button>
            </div>
            <div class="filter-grid">
                <div class="filter-item">
                    <label for="club" class="label-filter">Club</label>
                    <select id="club" v-model="filters.club" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">{{ club.club_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="runner" class="label-filter">Sportiv</label>
                    <select id="runner" v-model="filters.runner" class="custom-select">
                        <option value="all">Toți</option>
                        <option v-for="r in filterData.runners" :key="r.id" :value="r.id">{{ r.full_name }}</option>
                    </select>
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
                <div>Nu s-au găsit afilieri.</div>
            </div>
        </div>

        <Create ref="modal" @save="saveMembership" />
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
    "club": "all",
    "runner": "all"
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
        const res = await axios.get('/memberships.json', { params: cleanParams });
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
    const res = await axios.get('/memberships/filters.json')
    filterData.value = res.data
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
    getData();
}

function createNew() {
    modal.value.createNew()
}

function saveMembership() {
    filters["sorting[sort_by]"] = "created_at"
    filters["sorting[direction]"] = "desc"
}
</script>

<style scoped src="../shared/index.css"></style>
