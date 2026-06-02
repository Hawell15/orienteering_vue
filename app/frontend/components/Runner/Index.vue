<template>
    <div class="index-page">
        <div class="index-hero">
            <div class="index-hero-inner">
                <div class="index-title-block">
                    <span class="index-eyebrow">👤 Listă</span>
                    <h1 class="index-title">Sportivi</h1>
                </div>
                <span class="index-count">{{ data.length }}</span>
                <div class="search-box">
                    <input type="text" v-model="filters.search" placeholder="Caută sportivi…" class="search-input" />
                </div>
                <a class="add-btn" href="/runners/license">🪪 Licențe</a>
                <button v-if="isAdmin" class="add-btn" @click="createNew">＋ Adaugă sportiv</button>
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
                    <label for="membership" class="label-filter">Afiliere</label>
                    <select id="membership" v-model="filters.membership" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">{{ club.club_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="category" class="label-filter">Categoria actuală</label>
                    <select id="category" v-model="filters.category" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="cat in filterData.categories" :key="cat.id" :value="cat.id">{{ cat.category_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="best_category" class="label-filter">Titlu sportiv</label>
                    <select id="best_category" v-model="filters.best_category" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="cat in filterData.categories" :key="cat.id" :value="cat.id">{{ cat.category_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="gender" class="label-filter">Genul</label>
                    <select id="gender" v-model="filters.gender" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="g in filterData.genders" :key="g" :value="g">{{ g }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Anul nașterii</label>
                    <div class="range-wrapper">
                        <input type="number" v-model="filters['yob[from]']" min="0" class="custom-input" placeholder="De la" />
                        <span class="range-separator">—</span>
                        <input type="number" v-model="filters['yob[to]']" min="0" class="custom-input" placeholder="Până la" />
                    </div>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Indicatori</label>
                    <div class="checkbox-row">
                        <label class="checkbox-pill" :class="{ checked: filters.wre === true || filters.wre === 'true' }">
                            <input type="checkbox" v-model="filters.wre" /> WRE
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
                <div>Nu s-au găsit sportivi.</div>
            </div>
        </div>

        <Create ref="modal" @save="saveRunner" />
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

const DEFAULT_FILTERS = {
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc",
    "yob[from]": "1000",
    "yob[to]": "2100",
    "search": "",
    "club": "all",
    "membership": "all",
    "category": "all",
    "best_category": "all",
    "wre": "false",
    "gender": "all"
}

const filters = reactive({ ...DEFAULT_FILTERS });

let debounceTimeout = null;

const modal = ref(null)

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
        { from: "yob[from]", to: "yob[to]" },
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
        const res = await axios.get('/runners.json', { params: cleanParams });
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
    const cleanParams = {};
    cleanParams["competition"] = filters.competition

    const res = await axios.get('/runners/filters.json', { params: cleanParams })

    filterData.value = res.data
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
    getData();
}

function createNew() {
    modal.value.createNew()
}

function saveRunner() {
    filters["sorting[sort_by]"] = "created_at"
    filters["sorting[direction]"] = "desc"
}
</script>

<style scoped src="../shared/index.css"></style>
